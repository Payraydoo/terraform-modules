# AWS VPC Terraform Module

This Terraform module creates a complete VPC infrastructure on AWS with public and private subnets, internet gateway, NAT gateway, route tables, and security groups optimized for running applications on ECS with an RDS PostgreSQL database.

## Features

- **VPC**: A fully configured VPC with DNS support and DNS hostnames enabled
- **Subnets**: One public and one private subnet for minimal footprint
- **Internet Gateway**: For public internet access from the public subnet
- **NAT Gateway**: For private subnets to access the internet while remaining private
- **Route Tables**: Properly configured for both public and private subnets
- **Security Groups**:
  - ECS security group with appropriate rules
  - RDS PostgreSQL security group with access from ECS
  - Optional bastion host security group
- **Bastion Host**: Optional EC2 instance for secure SSH access to resources in private subnets

## Usage

```hcl
module "vpc" {
  source = "./modules/vpc"  # Path to this module

  # Required variables
  vpc_cidr             = "10.0.0.0/16"
  environment          = "dev"
  tag_org_short_name   = "acme"
  availability_zones   = ["us-east-1a"]
  
  # Optional variables
  bastion_enabled      = true
  bastion_key_name     = "my-ssh-key"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_cidr | CIDR block for the VPC | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| tag_org_short_name | Short name of your organization for resource tagging | `string` | n/a | yes |
| availability_zones | List of availability zones to use (at least one) | `list(string)` | n/a | yes |
| bastion_enabled | Whether to create a bastion host | `bool` | `false` | no |
| bastion_key_name | SSH key name for the bastion host (required if bastion_enabled is true) | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the created VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| ecs_security_group_id | ID of the ECS security group |
| db_security_group_id | ID of the DB security group |
| bastion_public_ip | Public IP of the bastion host (if enabled) |

## Security Considerations

1. The bastion host's security group allows SSH access from any IP (`0.0.0.0/0`). For production environments, it's recommended to restrict this to specific IP ranges.

2. The DB security group allows access only from ECS instances and the bastion host (if enabled), following the principle of least privilege.

## Adding the Required Variables File

Create a `variables.tf` file with the following content:

```hcl
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "tag_org_short_name" {
  description = "Short name of your organization for resource tagging"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones to use (at least one)"
  type        = list(string)
}

variable "bastion_enabled" {
  description = "Whether to create a bastion host"
  type        = bool
  default     = false
}

variable "bastion_key_name" {
  description = "SSH key name for the bastion host (required if bastion_enabled is true)"
  type        = string
  default     = null
}
```

## Adding the Required Outputs File

Create an `outputs.tf` file with the following content:

```hcl
output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "ecs_security_group_id" {
  description = "ID of the ECS security group"
  value       = aws_security_group.ecs.id
}

output "db_security_group_id" {
  description = "ID of the DB security group"
  value       = aws_security_group.db.id
}

output "bastion_public_ip" {
  description = "Public IP of the bastion host (if enabled)"
  value       = var.bastion_enabled ? aws_instance.bastion[0].public_ip : null
}
```

## Example Integration with ECS and RDS

Here's how you might use this VPC module in a larger infrastructure setup:

```hcl
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr           = "10.0.0.0/16"
  environment        = "dev"
  tag_org_short_name = "acme"
  availability_zones = ["us-east-1a"]
  bastion_enabled    = true
  bastion_key_name   = "my-ssh-key"
}

resource "aws_ecs_cluster" "main" {
  name = "${var.tag_org_short_name}-${var.environment}-cluster"
  
  tags = {
    Environment = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.tag_org_short_name}-${var.environment}-db-subnet-group"
  subnet_ids = module.vpc.private_subnet_ids
  
  tags = {
    Environment = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.tag_org_short_name}-${var.environment}-db"
  engine                 = "postgres"
  engine_version         = "14.6"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "application"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.vpc.db_security_group_id]
  skip_final_snapshot    = true
  
  tags = {
    Environment = var.environment
    Organization = var.tag_org_short_name
  }
}
```

## Customization

This module is designed to be minimal while providing all necessary components for a basic VPC setup. If you need more subnets or want to span multiple availability zones, modify the module to increase the count parameter in the subnet resources.