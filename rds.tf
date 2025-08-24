# RDS Database Infrastructure
# Managed MySQL database with automated backups and monitoring

# Random password for database
resource "random_password" "db_password" {
  length  = 16
  special = true
}

# AWS Secrets Manager - Secure password storage
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.project_name}-db-password"
  description             = "Database password for ${var.project_name}"
  recovery_window_in_days = 7

  tags = {
    Name = "${var.project_name}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
  })
}

# Database Subnet Group - Multi-AZ deployment
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

# Database Parameter Group - Custom configuration
resource "aws_db_parameter_group" "main" {
  family = "mysql8.0"
  name   = "${var.project_name}-db-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "16777216"  # 16MB for t3.micro
  }

  tags = {
    Name = "${var.project_name}-db-parameter-group"
  }
}

# RDS Instance - Managed MySQL Database
resource "aws_db_instance" "main" {
  identifier = "${var.project_name}-database"

  # Engine Configuration
  engine         = var.db_engine
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  # Storage Configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false

  # Backup Configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Monitoring and Performance
  performance_insights_enabled = false
  monitoring_interval         = 60
  monitoring_role_arn        = aws_iam_role.rds_enhanced_monitoring.arn

  # High Availability
  multi_az = false  # Set to true for production

  # Parameter and Option Groups
  parameter_group_name = aws_db_parameter_group.main.name

  # Deletion Protection
  deletion_protection = false  # Set to true for production
  skip_final_snapshot = true   # Set to false for production

  tags = {
    Name = "${var.project_name}-database"
  }

  depends_on = [aws_cloudwatch_log_group.rds]
}

# CloudWatch Log Group for RDS
resource "aws_cloudwatch_log_group" "rds" {
  name              = "/aws/rds/instance/${var.project_name}-database/error"
  retention_in_days = var.log_retention_days

  tags = {
    Name = "${var.project_name}-rds-logs"
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-rds-monitoring-role"
  }
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Database Connection Information Output
output "database_endpoint" {
  description = "Database endpoint for application connection"
  value       = aws_db_instance.main.endpoint
  sensitive   = false
}

output "database_port" {
  description = "Database port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "database_username" {
  description = "Database username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "database_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}