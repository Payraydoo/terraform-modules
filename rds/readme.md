# AWS RDS PostgreSQL Terraform Module

This Terraform module creates an Amazon RDS PostgreSQL database instance with associated subnet group. The module is designed to be simple yet flexible enough to handle most common PostgreSQL deployment scenarios, including secure password management.

## Features

- PostgreSQL 14.7 database instance
- Configurable instance class and storage
- Storage auto-scaling with configurable maximum limit
- Encrypted storage using gp3 volumes
- Backup configuration with 7-day retention
- Database subnet group for VPC deployment
- Security group integration
- Resource tagging with organization and environment variables
- **Secure random password generation**
- **Optional AWS Secrets Manager integration**

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13.0 |
| aws | >= 3.0.0 |
| random | ~> 3.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 3.0.0 |
| random | ~> 3.0 |

## Resources Created

- AWS DB Subnet Group (`aws_db_subnet_group`)
- AWS RDS Instance (`aws_db_instance`)
- Random Password (`random_password`)
- AWS Secrets Manager Secret and Version (optional)

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| tag_org_short_name | Short name of your organization for resource naming | `string` | n/a | yes |
| environment | Environment name (e.g., dev, staging, prod) | `string` | n/a | yes |
| db_subnet_group_name | Name for the database subnet group | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs where the RDS instance will be deployed | `list(string)` | n/a | yes |
| db_instance_class | The instance type of the RDS instance | `string` | `"db.t3.micro"` | no |
| db_name | Name of the database to create when the instance is created | `string` | n/a | yes |
| db_username | Username for the master DB user | `string` | `"postgres"` | no |
| db_password | Password for the master DB user (leave empty to generate a random password) | `string` | `""` | no |
| db_sg_id | ID of the security group to associate with the RDS instance | `string` | n/a | yes |
| store_password_in_secrets_manager | Whether to store the database password in AWS Secrets Manager | `bool` | `false` | no |

## Output Values

| Name | Description |
|------|-------------|
| db_instance_id | The RDS instance ID |
| db_instance_address | The address of the RDS instance |
| db_instance_endpoint | The connection endpoint for the RDS instance |
| db_instance_arn | The ARN of the RDS instance |
| db_subnet_group_id | The ID of the DB subnet group |
| db_name | The database name |
| db_username | The master username for the database |
| db_password | The database password (if randomly generated) |
| db_password_secret_arn | ARN of the Secrets Manager secret containing database credentials (if enabled) |

## Password Management Features

This module offers two approaches to password management:

1. **Random Password Generation**: If `db_password` is left empty (default), the module generates a secure random 16-character password with a mix of uppercase, lowercase, numbers, and special characters.

2. **AWS Secrets Manager Integration**: When `store_password_in_secrets_manager` is set to `true`, the module:
   - Creates a secret in AWS Secrets Manager
   - Stores the database credentials (including connection information) in JSON format
   - Returns the secret's ARN as an output

## Usage Examples

### Basic Usage with Auto-Generated Password

```hcl
module "postgres_db" {
  source = "./modules/rds-postgres"

  tag_org_short_name    = "acme"
  environment           = "dev"
  
  db_subnet_group_name  = "acme-dev-subnet-group"
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_sg_id              = module.security_groups.db_security_group_id
  
  db_instance_class     = "db.t3.small"
  db_name               = "application_db"
  db_username           = "dbadmin"
  # Password will be auto-generated
}

# The password can be accessed via the output
output "database_password" {
  value       = module.postgres_db.db_password
  sensitive   = true
}
```

### Using AWS Secrets Manager

```hcl
module "postgres_db" {
  source = "./modules/rds-postgres"

  tag_org_short_name    = "acme"
  environment           = "prod"
  
  db_subnet_group_name  = "acme-prod-subnet-group"
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_sg_id              = module.security_groups.db_security_group_id
  
  db_instance_class     = "db.t3.medium"
  db_name               = "application_db"
  db_username           = "dbadmin"
  
  # Enable Secrets Manager integration
  store_password_in_secrets_manager = true
}

# Applications can reference the secret by ARN
output "db_secret_arn" {
  value = module.postgres_db.db_password_secret_arn
}
```

### Using a Specific Password

```hcl
module "postgres_db" {
  source = "./modules/rds-postgres"

  tag_org_short_name    = "acme"
  environment           = "staging"
  
  db_subnet_group_name  = "acme-staging-subnet-group"
  private_subnet_ids    = module.vpc.private_subnet_ids
  db_sg_id              = module.security_groups.db_security_group_id
  
  db_instance_class     = "db.t3.small"
  db_name               = "application_db"
  db_username           = "dbadmin"
  db_password           = var.specific_password  # Use this approach only for non-production environments
}
```

## Notes

- The module creates a PostgreSQL 14.7 instance by default
- Storage is encrypted using the AWS-managed KMS key
- Storage auto-scaling is enabled with a maximum of 100GB
- Single-AZ deployment is configured by default (`multi_az = false`)
- Automatic backups are retained for 7 days
- The random password contains a mix of:
  - At least 2 uppercase letters
  - At least 2 lowercase letters
  - At least 2 numbers
  - At least 2 special characters
- When using Secrets Manager, connection details are stored in JSON format

## Security Considerations

- When the `db_password` variable is left empty, a secure random password is generated
- The `db_password` output is marked as sensitive to prevent accidental exposure
- AWS Secrets Manager integration provides a more secure way to manage and rotate credentials
- The module expects a security group ID to be provided that should have appropriate ingress/egress rules
- The database is deployed in private subnets for better security

## Best Practices

1. **Production Environments**:
   - Always use `store_password_in_secrets_manager = true`
   - Consider setting `prevent_destroy = true` in the lifecycle block
   - Use `multi_az = true` for high availability

2. **Development/Testing**:
   - Auto-generated passwords are convenient for ephemeral environments
   - Always use unique passwords even for non-production environments

3. **General**:
   - Avoid hardcoding passwords in your Terraform configurations
   - Consider using IAM authentication for database access where possible
   - Rotate passwords regularly
