terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }
  # Note 
  # S3 Bucket configuration will be added
  # For terraform state.
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = var.aws_default_region
}


################################
#    ECS CLUSTER DEFINITION    #
################################

/*
  ECS Cluster Provisioning
*/
resource "aws_ecs_cluster" "ecs" {

  name = var.cluster_name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = merge(var.default_tags, tomap({
    Cluster = var.cluster_name
  }))

}
################################
#########     END     ##########
################################



################################
#   LAUNCH CONF. & AUTOSCALE   #
################################

/*
  Launch Configuration Provisioning
*/
resource "aws_launch_configuration" "ecs_launch_configuration" {

  name_prefix   = "${var.app_name}-${var.app_environment}-ecs-launch-configuration-"
  image_id      = var.ecs_ami_id
  instance_type = var.ecs_instance_type

  iam_instance_profile = var.ecs_instance_profile

  root_block_device {
    volume_type           = "standard"
    volume_size           = 30
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  security_groups = var.container_instance_security_group_ids

  key_name = var.ecs_key_pair_name

  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.cluster_name} >> /etc/ecs/ecs.config
  EOF
}


/*
  AutoScalingGroup Provisioning
*/
resource "aws_autoscaling_group" "ecs_autoscaling_group" {

  name_prefix = "${var.app_name}-${var.app_environment}-ecs-asg-"

  max_size         = var.max_instance_size
  min_size         = var.min_instance_size
  desired_capacity = var.desired_capacity

  vpc_zone_identifier = [var.does_EC2_hasPublicIP == true ? var.public_subnet_for_container_instance : var.private_subnet_for_container_instance]

  launch_configuration = aws_launch_configuration.ecs_launch_configuration.name

}
################################
#########     END     ##########
################################



################################
#   APPLICATION LOADBALANCER   #
################################

resource "aws_lb" "application_load_balancer" {

  name               = "${var.app_name}-${var.app_environment}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = var.public_subnet_ids
  security_groups    = var.security_groups_for_alb

  tags = {
    Name        = "${var.app_name}-alb"
    Environment = var.app_environment
  }

}
resource "aws_lb_target_group" "target_group" {

  name_prefix = "tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/api/versions"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.app_name}-loadbalancer-targetgroup"
    Environment = var.app_environment
  }

}



resource "aws_lb_listener" "alb_listener_forward_ssl" {

  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy      = var.certificate_ssl_policy
  certificate_arn = var.certificate_arn_code

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }

}

resource "aws_lb_listener" "alb_listener_redirect_ssl" {
  load_balancer_arn = aws_lb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

}
################################
#########     END     ##########
################################



################################
#   ECS SERVICE & TASK DEF.    #
################################
resource "aws_ecs_task_definition" "aws-ecs-task" {

  family = "${var.app_name}-task"

  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.app_name}-${var.app_environment}-container",
      "image": "${var.aws_ecr_repository_url}",
      "environment":[],
      "mountPoints": [
        {
          "containerPath": "/var/run/docker.sock",
          "sourceVolume": "DockerSocket"
        }
      ],
      "memoryReservation": 256,
      "essential": true,
      "portMappings": [
        {
          "hostPort": 0,
          "protocol": "tcp",
          "containerPort": ${var.container_port}
        }
      ]
    }
  ]
  DEFINITION

  requires_compatibilities = ["EC2"]

  volume {
    name      = "DockerSocket"
    host_path = "/var/run/docker.sock"
  }

  tags = {
    Name        = "${var.app_name}-ecs-td"
    Environment = var.app_environment
  }
}


data "aws_ecs_task_definition" "main" {
  task_definition = aws_ecs_task_definition.aws-ecs-task.family
}


resource "aws_ecs_service" "aws-ecs-service" {

  name                 = "${var.app_name}-${var.app_environment}-ecs-service"
  cluster              = var.cluster_name
  task_definition      = "${aws_ecs_task_definition.aws-ecs-task.family}:${max(aws_ecs_task_definition.aws-ecs-task.revision, data.aws_ecs_task_definition.main.revision)}"
  launch_type          = "EC2"
  scheduling_strategy  = "REPLICA"
  desired_count        = 2
  force_new_deployment = true

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.app_name}-${var.app_environment}-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener.alb_listener_forward_ssl,
    aws_lb_listener.alb_listener_redirect_ssl
  ]
}
################################
#########     END     ##########
################################
