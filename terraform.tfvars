# AWS Infrastructure Configuration
# Customize these values for your deployment

# Project Details
project_name = "aws-infra-platform"
environment  = "dev"
owner        = "DevOps-Team"

# AWS Configuration
aws_region = "us-east-1"

# Network Configuration - Our Virtual Private Cloud
vpc_cidr = "10.0.0.0/16"

# Subnet Configuration (Multi-AZ for high availability)
public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]     # Load Balancers
private_subnet_cidrs  = ["10.0.10.0/24", "10.0.20.0/24"]   # Applications
database_subnet_cidrs = ["10.0.100.0/24", "10.0.200.0/24"] # Database

# Application Configuration
container_port = 3000

# ECS Configuration (Container Orchestration)
ecs_service_name  = "web-app"
ecs_task_cpu      = 512  # 0.5 vCPU
ecs_task_memory   = 1024 # 1 GB RAM
ecs_desired_count = 2    # 2 containers for redundancy

# Database Configuration
db_engine                  = "mysql"
db_engine_version          = "8.0"
db_instance_class          = "db.t3.micro" # Free tier eligible
db_allocated_storage       = 20            # GB
db_max_allocated_storage   = 100           # Auto-scaling limit
db_name                    = "webapp"
db_username                = "admin"
db_backup_retention_period = 7 # Days

# Monitoring Configuration
enable_monitoring  = true
log_retention_days = 14

# Load Balancer Health Checks
health_check_path     = "/"
health_check_interval = 30 # seconds
health_check_timeout  = 5  # seconds
healthy_threshold     = 2  # consecutive successes
unhealthy_threshold   = 2  # consecutive failures