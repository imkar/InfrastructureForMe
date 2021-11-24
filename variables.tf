
variable "aws_default_region" {
  description = "Value of the Name tag for the ECS Cluster"
  default = "eu-west-1"
}

variable "cluster_name" {
  description = "Value of the Name tag for the ECS Cluster"
  type        = string
  default     = "test-cluster-with-terraform"
}

variable "default_tags" {
  description = "Default tags for provisioned aws properties"
}

variable "app_name" {
  description = "Name of the Application"
}

variable "app_environment" {
  description = "Environment of the Application (Test, Staging or Production)"
}

variable "ecs_ami_id" {
  description = "AMI id for the EC2 Instances images"
}

variable "ecs_instance_type" {
  description = "EC2 Instance type of the machines inside the ECS Cluster"
}

variable "ecs_key_pair_name" {
  description = "EC2 Keypair (.pem) file name"
}

variable "max_instance_size" {
  description = "Maximum number of Instances for horizontal scale on ECS Cluster"
}

variable "min_instance_size" {
  description = "Minimum number of Instances for horizontal scale on ECS Cluster"
}

variable "desired_capacity" {
  description = "Desired number of Instances for horizontal scale on ECS Cluster"
}

variable "private_subnet_id" {
  description = "Private Subnet ID of the ECS Cluster"
}

variable "public_subnet_ids" {
  description = "Public Subnet ID list for the LoadBalancer"
}

variable "public_subnet_for_container_instance" {
  description = "Public Subnet ID for Container Instances"
}

variable "private_subnet_for_container_instance" {
  description = "Private Subnet ID for Container Instances"
}

variable "vpc_id" {
  description = "VPC id of the ECS Cluster"
}

variable "ecs_instance_profile" {
  description = "IAM Instance Profile"
}

variable "aws_ecr_repository_url" {
  description = "ECR Repo URL"
}

variable "security_groups_for_alb" {
  type    = list(string)
  description = "Application LoadBalancer Security Groups List"
}

variable "container_instance_security_group_ids" {
  type    = list(string)
  description = "ECS Private Cluster Instance Security Group IDs List"
}

variable "certificate_ssl_policy" {
  description = "SSL Certificate Policy"
}

variable "certificate_arn_code" {
  description = "SSL Certificate ARN on AWS ACM"
}

variable "container_port" {
  description = "Container Port number that exposed"
}

variable "does_EC2_hasPublicIP" {
  description = "Is container instances will be open to public or not"
}