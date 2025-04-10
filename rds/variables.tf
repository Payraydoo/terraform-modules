variable "tag_org_short_name" {
  description = "Short name of your organization for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
}

variable "db_subnet_group_name" {
  description = "Name for the database subnet group"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs where the RDS instance will be deployed"
  type        = list(string)
}

variable "db_instance_class" {
  description = "The instance type of the RDS instance (e.g., db.t3.micro)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Name of the database to create when the instance is created"
  type        = string
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Password for the master DB user (leave empty to generate a random password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "db_sg_id" {
  description = "ID of the security group to associate with the RDS instance"
  type        = string
}

variable "store_password_in_secrets_manager" {
  description = "Whether to store the database password in AWS Secrets Manager"
  type        = bool
  default     = false
}