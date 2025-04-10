terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0.0"
    }
  }
}

resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_lower        = 2
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
}

resource "aws_db_subnet_group" "main" {
  name       = var.db_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-db-subnet-group"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_db_instance" "main" {
  identifier              = "${lower(var.tag_org_short_name)}-${var.environment}-postgres"
  engine                  = "postgres"
  engine_version          = "14.7"
  instance_class          = var.db_instance_class
  allocated_storage       = 20
  max_allocated_storage   = 100
  storage_type            = "gp3"
  storage_encrypted       = true
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password != "" ? var.db_password : random_password.db_password.result
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [var.db_sg_id]
  skip_final_snapshot     = true
  backup_retention_period = 7
  multi_az                = false

  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-postgres"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Store the generated password in AWS Secrets Manager if specified
resource "aws_secretsmanager_secret" "db_password" {
  count = var.store_password_in_secrets_manager ? 1 : 0
  
  name = "${var.tag_org_short_name}/${var.environment}/db/password"
  description = "Password for the ${var.tag_org_short_name}-${var.environment} PostgreSQL RDS instance"
  
  tags = {
    Name         = "${var.tag_org_short_name}-${var.environment}-db-password"
    Environment  = var.environment
    Organization = var.tag_org_short_name
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  count = var.store_password_in_secrets_manager ? 1 : 0
  
  secret_id     = aws_secretsmanager_secret.db_password[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password != "" ? var.db_password : random_password.db_password.result
    engine   = "postgres"
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}