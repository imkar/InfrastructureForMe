# Infrastructure for me - ECS Cluster

AWS Infrastructure provisioning shortcut for me, in order to create fast, reliable and zero-downtime scalable cluster, within my existing vpc, pre-configured private and public subnets, and security groups.

> **Important prerequistes before using this repository IaC.**

- VPC
- Private Subnet and Public Subnet
- KeyPair (.pem)
- ECR Repository (with Image)
- ACM SSL certificate
- Security Group for Internet-facing Application Loadbalancer
- Security Groups for Container Instances behind Loadbalancer.

  \*_Must **exist** already in your AWS Cloud_

## Usage:

- Fill the variables in "inputs.tfvars" file.
- Configure your aws secrets.

  ```bash
  aws configure
  ```

  ```bash
  terraform init
  terraform validate
  terraform plan -out InfraPlan -var-file inputs.tfvars
  terraform apply "InfraPlan"
  ```

## Notes:

- New features will be added.
- Outputs will be added.
- Images will be added for README.md
