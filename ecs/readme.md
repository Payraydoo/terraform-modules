# AWS ECS Cluster Terraform Module

This Terraform module creates a fully configured Amazon ECS cluster with EC2 instances as the compute capacity. The module sets up an ECS cluster with auto-scaling capabilities, IAM roles and policies, task definitions for multiple services, and CloudWatch logging.

## Features

- ECS cluster with Container Insights enabled
- Auto Scaling Group with configurable capacity
- IAM roles and policies for ECS instances and tasks
- Task definitions for Node.js, .NET, and Python applications
- ECS services for each task definition
- CloudWatch log groups for each service
- EC2 Launch Template with security hardening
- Capacity provider and strategy configuration

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0.0 |

## Resources Created

- ECS Cluster
- IAM Roles (instance role, task execution role)
- IAM Policies and Policy Attachments
- EC2 Launch Template
- Auto Scaling Group
- ECS Capacity Provider
- CloudWatch Log Groups
- ECS Task Definitions
- ECS Services

## Input Variables

| Name | Description | Type | Required |
|------|-------------|------|:--------:|
| tag_org_short_name | Short name of your organization for resource naming | `string` | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | yes |
| instance_type | EC2 instance type for ECS container instances | `string` | yes |
| ecs_sg_id | Security Group ID for ECS instances | `string` | yes |
| private_subnet_ids | List of private subnet IDs for the Auto Scaling Group | `list(string)` | yes |
| min_size | Minimum size of the Auto Scaling Group | `number` | yes |
| max_size | Maximum size of the Auto Scaling Group | `number` | yes |
| desired_capacity | Desired capacity of the Auto Scaling Group | `number` | yes |
| db_endpoint | Database endpoint in format host:port | `string` | yes |
| db_name | Database name | `string` | yes |
| db_username | Database username | `string` | yes |
| db_password | Database password | `string` | yes |

## Output Values

The module doesn't explicitly define outputs in the provided code, but you might want to add these:

```hcl
output "cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

output "cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "task_execution_role_arn" {
  description = "ARN of the ECS task execution role"
  value       = aws_iam_role.ecs_task_execution_role.arn
}

output "ecs_instance_role_name" {
  description = "Name of the ECS instance IAM role"
  value       = aws_iam_role.ecs_instance_role.name
}

output "nodejs_service_name" {
  description = "Name of the Node.js ECS service"
  value       = aws_ecs_service.nodejs.name
}

output "dotnet_service_name" {
  description = "Name of the .NET ECS service"
  value       = aws_ecs_service.dotnet.name
}

output "python_service_name" {
  description = "Name of the Python ECS service"
  value       = aws_ecs_service.python.name
}
```

## Usage Example

Below is an example of how to use this module in your Terraform code:

```hcl
module "ecs_cluster" {
  source = "./modules/ecs-cluster"  # Path to this module

  # Required variables
  tag_org_short_name = "acme"
  environment        = "prod"
  instance_type      = "t3.medium"
  
  # Networking
  ecs_sg_id          = module.security_groups.ecs_sg_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  # Auto Scaling configuration
  min_size           = 2
  max_size           = 6
  desired_capacity   = 3
  
  # Database configuration
  db_endpoint        = module.rds.db_endpoint
  db_name            = "application_db"
  db_username        = var.db_username  # Consider using AWS Secrets Manager
  db_password        = var.db_password  # Consider using AWS Secrets Manager
}
```

## Prerequisites

Before using this module, you need to:

1. Have a VPC with public and private subnets
2. Create security groups for ECS instances
3. Set up a database (RDS or Aurora)
4. Create ECR repositories for your container images:
   - nodejs-app
   - dotnet-app
   - python-app
5. Create a `user_data.sh` script in the module directory for EC2 instance initialization

## Notes

- The module assumes you have ECR repositories with the names `nodejs-app`, `dotnet-app`, and `python-app` in your AWS account
- Container images are referenced with the `:latest` tag - consider using specific version tags for production
- The module uses an ECS-optimized Amazon Linux 2 AMI
- EC2 instances are configured with enhanced security features (IMDSv2, encrypted EBS volumes)
- Container Insights is enabled on the ECS cluster for monitoring

## Security Considerations

- Database credentials are passed as plain text variables. For production, consider using AWS Secrets Manager or AWS Parameter Store
- The module enforces IMDSv2 for EC2 instances
- EBS volumes are encrypted by default
- CloudWatch logs are enabled for all services

## User Data Script

Make sure to create a `user_data.sh` file in the module directory with content similar to:

```bash
#!/bin/bash
echo "ECS_CLUSTER=${cluster_name}" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_CONTAINER_METADATA=true" >> /etc/ecs/ecs.config
echo "ECS_ENABLE_SPOT_INSTANCE_DRAINING=true" >> /etc/ecs/ecs.config
yum install -y amazon-cloudwatch-agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent
```

## License

Specify your license here