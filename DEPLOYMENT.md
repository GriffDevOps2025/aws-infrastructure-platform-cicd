# Deployment Guide

## 🚀 AWS Infrastructure Platform Deployment Procedures

### Overview
This document provides comprehensive deployment procedures for the AWS Infrastructure Platform, including initial setup, application deployment, and operational procedures.

## 📋 Prerequisites

### Required Tools
- **AWS CLI**: Version 2.0+ configured with appropriate credentials
- **Terraform**: Version 1.0+ for infrastructure management
- **Docker**: Version 20.0+ for container builds
- **Git**: Version control for source code management
- **Node.js**: Version 18+ for local development (optional)

### AWS Permissions Required
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ecs:*",
        "rds:*",
        "elasticloadbalancing:*",
        "ecr:*",
        "iam:*",
        "secretsmanager:*",
        "logs:*",
        "application-autoscaling:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### Environment Setup
```bash
# Verify AWS CLI configuration
aws sts get-caller-identity

# Verify Terraform installation
terraform version

# Verify Docker installation  
docker --version
```

## 🏗️ Initial Infrastructure Deployment

### Step 1: Repository Setup
```bash
# Clone the repository
git clone <repository-url>
cd aws-infrastructure-cicd

# Verify project structure
ls -la
```

### Step 2: Terraform Initialization
```bash
# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Format Terraform files
terraform fmt
```

### Step 3: Infrastructure Planning
```bash
# Review planned changes
terraform plan

# Save plan for review
terraform plan -out=tfplan

# Review the plan file
terraform show tfplan
```

### Step 4: Infrastructure Deployment
```bash
# Apply infrastructure changes
terraform apply

# Or apply with saved plan
terraform apply tfplan

# Confirm deployment when prompted
# Type: yes
```

### Step 5: Verify Infrastructure
```bash
# Get infrastructure outputs
terraform output

# Verify VPC creation
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=aws-infra-platform-vpc"

# Verify ECS cluster
aws ecs describe-clusters --clusters aws-infra-platform-cluster

# Verify RDS instance
aws rds describe-db-instances --db-instance-identifier aws-infra-platform-database
```

**Expected Deployment Time**: 10-15 minutes

## 🐳 Container Application Deployment

### Step 1: Build Application Image
```bash
# Build Docker image
docker build -t aws-infra-platform-app .

# Verify image creation
docker images | grep aws-infra-platform-app

# Test image locally (optional)
docker run -p 8080:80 aws-infra-platform-app
```

### Step 2: ECR Authentication
```bash
# Get ECR repository URL
ECR_URL=$(terraform output -raw ecr_repository_url)
echo $ECR_URL

# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
```

### Step 3: Push Image to ECR
```bash
# Tag image for ECR
docker tag aws-infra-platform-app:latest $ECR_URL:latest

# Push image to ECR
docker push $ECR_URL:latest

# Verify image in ECR
aws ecr describe-images --repository-name aws-infra-platform-app
```

### Step 4: Deploy to ECS
```bash
# Force service update to pull new image
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --force-new-deployment

# Monitor deployment progress
aws ecs describe-services \
    --cluster aws-infra-platform-cluster \
    --services web-app \
    --query 'services[0].deployments[0].rolloutState'
```

### Step 5: Verify Application Deployment
```bash
# Get load balancer URL
ALB_URL=$(terraform output -raw load_balancer_url)
echo $ALB_URL

# Test application endpoint
curl $ALB_URL

# Test health endpoint
curl $ALB_URL/api/health

# Check container logs
aws logs tail /ecs/aws-infra-platform --follow
```

**Expected Deployment Time**: 5-10 minutes

## 🔄 Update Deployment Procedures

### Application Code Updates

#### Method 1: Manual Deployment
```bash
# 1. Update application code
# Edit files in app/ directory

# 2. Rebuild image
docker build -t aws-infra-platform-app .

# 3. Login to ECR (if not already logged in)
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw ecr_repository_url)

# 4. Tag and push new image
docker tag aws-infra-platform-app:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest

# 5. Force ECS deployment
aws ecs update-service --cluster aws-infra-platform-cluster --service web-app --force-new-deployment

# 6. Monitor deployment
aws ecs describe-services --cluster aws-infra-platform-cluster --services web-app
```

#### Method 2: Blue-Green Deployment
```bash
# 1. Create new task definition revision
# Update image tag in ecs.tf or create new revision

# 2. Update ECS service with new task definition
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --task-definition aws-infra-platform-task:NEW_REVISION

# 3. Monitor health checks
aws elbv2 describe-target-health \
    --target-group-arn $(terraform output -raw target_group_arn)

# 4. Verify application functionality
curl $(terraform output -raw load_balancer_url)
```

### Infrastructure Updates
```bash
# 1. Update Terraform configuration files
# Edit .tf files as needed

# 2. Plan infrastructure changes
terraform plan -out=tfplan

# 3. Review changes carefully
terraform show tfplan

# 4. Apply changes
terraform apply tfplan

# 5. Verify updates
terraform output
```

## 📊 Monitoring and Troubleshooting

### Health Check Procedures
```bash
# Check ECS service health
aws ecs describe-services \
    --cluster aws-infra-platform-cluster \
    --services web-app

# Check container health
aws ecs list-tasks \
    --cluster aws-infra-platform-cluster \
    --service-name web-app

# Check load balancer targets
aws elbv2 describe-target-health \
    --target-group-arn $(aws elbv2 describe-target-groups --names aws-infra-platform-tg --query 'TargetGroups[0].TargetGroupArn' --output text)

# Test application endpoints
curl -f $(terraform output -raw load_balancer_url) || echo "Health check failed"
curl -f $(terraform output -raw load_balancer_url)/api/health || echo "Database health check failed"
```

### Log Analysis
```bash
# View container logs
aws logs describe-log-streams \
    --log-group-name "/ecs/aws-infra-platform" \
    --order-by LastEventTime --descending

# Get recent log events
aws logs get-log-events \
    --log-group-name "/ecs/aws-infra-platform" \
    --log-stream-name "LATEST_STREAM_NAME"

# Follow logs in real-time
aws logs tail /ecs/aws-infra-platform --follow

# Filter logs by error level
aws logs filter-log-events \
    --log-group-name "/ecs/aws-infra-platform" \
    --filter-pattern "ERROR"
```

### Performance Monitoring
```bash
# Check ECS service metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=web-app Name=ClusterName,Value=aws-infra-platform-cluster \
    --start-time 2025-08-24T00:00:00Z \
    --end-time 2025-08-24T01:00:00Z \
    --period 300 \
    --statistics Average

# Check ALB metrics
aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name RequestCount \
    --dimensions Name=LoadBalancer,Value=app/aws-infra-platform-alb/LOAD_BALANCER_ID \
    --start-time 2025-08-24T00:00:00Z \
    --end-time 2025-08-24T01:00:00Z \
    --period 300 \
    --statistics Sum
```

## 🔧 Common Troubleshooting Scenarios

### Scenario 1: Container Startup Failures
```bash
# Symptoms: ECS tasks failing to start
# Diagnosis:
aws ecs describe-tasks --cluster aws-infra-platform-cluster --tasks FAILED_TASK_ARN

# Check container logs
aws logs get-log-events --log-group-name "/ecs/aws-infra-platform" --log-stream-name "CONTAINER_STREAM"

# Common causes:
# - Database connection issues
# - Missing environment variables
# - Container port configuration
# - Resource constraints

# Solutions:
# 1. Verify database endpoint and credentials
# 2. Check environment variable configuration in ecs.tf
# 3. Ensure container port matches load balancer configuration
# 4. Review task definition resource allocation
```

### Scenario 2: Load Balancer Health Check Failures
```bash
# Symptoms: Targets showing as unhealthy
# Diagnosis:
aws elbv2 describe-target-health --target-group-arn TARGET_GROUP_ARN

# Check health check configuration
aws elbv2 describe-target-groups --target-group-arns TARGET_GROUP_ARN

# Common causes:
# - Health check path not responding (/)
# - Container port mismatch
# - Security group blocking traffic
# - Application startup time exceeding health check timeout

# Solutions:
# 1. Verify health endpoint responds correctly: curl CONTAINER_IP/
# 2. Check port configuration in task definition and service
# 3. Review security group rules for port 80
# 4. Adjust health check timeout and interval settings
```

### Scenario 3: Database Connection Issues
```bash
# Symptoms: Application errors related to database connectivity
# Diagnosis:
# Test database connectivity from container
aws ecs execute-command \
    --cluster aws-infra-platform-cluster \
    --task TASK_ARN \
    --container aws-infra-platform-container \
    --interactive \
    --command "mysql -h DB_HOST -u DB_USER -p"

# Common causes:
# - Security group blocking database port
# - Database endpoint configuration
# - Credentials in Secrets Manager
# - Database instance status

# Solutions:
# 1. Verify RDS security group allows port 3306 from ECS security group
# 2. Check database endpoint in environment variables
# 3. Verify database credentials in Secrets Manager
# 4. Ensure RDS instance is in available state
```

### Scenario 4: High CPU/Memory Usage
```bash
# Symptoms: Auto-scaling triggering frequently
# Diagnosis:
aws cloudwatch get-metric-statistics \
    --namespace AWS/ECS \
    --metric-name CPUUtilization \
    --dimensions Name=ServiceName,Value=web-app \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%SZ) \
    --period 300 \
    --statistics Average,Maximum

# Solutions:
# 1. Optimize application code for better resource usage
# 2. Increase task definition CPU/memory allocation
# 3. Implement connection pooling for database
# 4. Add caching layer to reduce database load
# 5. Optimize Docker image size and layers
```

## 🔄 Rollback Procedures

### Application Rollback
```bash
# Method 1: Rollback to previous task definition
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --task-definition aws-infra-platform-task:PREVIOUS_REVISION

# Method 2: Rollback using previous ECR image
# Tag and push previous working image
docker pull ECR_URL:PREVIOUS_TAG
docker tag ECR_URL:PREVIOUS_TAG ECR_URL:latest
docker push ECR_URL:latest

# Force service update
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --force-new-deployment
```

### Infrastructure Rollback
```bash
# Method 1: Using Terraform state
terraform apply -target=RESOURCE_TO_ROLLBACK

# Method 2: Restore from backup
# If using S3 backend (recommended for production)
terraform init -backend-config="key=infrastructure/backup/terraform.tfstate"
terraform apply

# Method 3: Selective resource recreation
terraform taint RESOURCE_NAME
terraform apply
```

## 🔐 Security Procedures

### Credential Rotation
```bash
# Rotate database password
aws secretsmanager update-secret \
    --secret-id aws-infra-platform-db-password \
    --secret-string "NEW_PASSWORD"

# Force ECS service update to pickup new credentials
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --force-new-deployment
```

### Security Group Updates
```bash
# Update security group rules via Terraform
# Edit security group configuration in main.tf
terraform plan
terraform apply

# Emergency security group update via CLI
aws ec2 revoke-security-group-ingress \
    --group-id sg-xxxxxxxxx \
    --protocol tcp \
    --port 80 \
    --source-group sg-yyyyyyyyy
```

## 📈 Scaling Procedures

### Manual Scaling
```bash
# Scale ECS service manually
aws ecs update-service \
    --cluster aws-infra-platform-cluster \
    --service web-app \
    --desired-count 5

# Update auto-scaling limits
aws application-autoscaling register-scalable-target \
    --service-namespace ecs \
    --resource-id service/aws-infra-platform-cluster/web-app \
    --scalable-dimension ecs:service:DesiredCount \
    --min-capacity 2 \
    --max-capacity 20
```

### Database Scaling
```bash
# Scale RDS instance
aws rds modify-db-instance \
    --db-instance-identifier aws-infra-platform-database \
    --db-instance-class db.t3.small \
    --apply-immediately

# Add read replica (future enhancement)
aws rds create-db-instance-read-replica \
    --db-instance-identifier aws-infra-platform-database-read-1 \
    --source-db-instance-identifier aws-infra-platform-database
```

## 🧪 Testing Procedures

### Deployment Testing
```bash
# Automated testing script
#!/bin/bash
ALB_URL=$(terraform output -raw load_balancer_url)

# Test basic connectivity
echo "Testing basic connectivity..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL)
if [ $HTTP_STATUS -eq 200 ]; then
    echo "✅ Basic connectivity test passed"
else
    echo "❌ Basic connectivity test failed (HTTP $HTTP_STATUS)"
    exit 1
fi

# Test API health endpoint
echo "Testing API health endpoint..."
HEALTH_RESPONSE=$(curl -s $ALB_URL/api/health)
if echo $HEALTH_RESPONSE | grep -q "healthy"; then
    echo "✅ Health check test passed"
else
    echo "❌ Health check test failed"
    exit 1
fi

# Test database connectivity
echo "Testing database connectivity..."
if echo $HEALTH_RESPONSE | grep -q '"database":"connected"'; then
    echo "✅ Database connectivity test passed"
else
    echo "❌ Database connectivity test failed"
    exit 1
fi

echo "🎉 All tests passed! Deployment successful."
```

### Performance Testing
```bash
# Load testing with Apache Bench
ab -n 1000 -c 10 $(terraform output -raw load_balancer_url)/

# Monitor during load test
watch aws ecs describe-services \
    --cluster aws-infra-platform-cluster \
    --services web-app \
    --query 'services[0].runningCount'
```

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Code changes reviewed and tested locally
- [ ] Terraform configuration validated
- [ ] Database migration scripts prepared (if applicable)
- [ ] Deployment window scheduled
- [ ] Rollback plan prepared
- [ ] Monitoring alerts configured

### During Deployment
- [ ] Infrastructure changes applied successfully
- [ ] Container image built and pushed to ECR
- [ ] ECS service updated with new task definition
- [ ] Health checks passing
- [ ] Application endpoints responding correctly
- [ ] Database connectivity verified

### Post-Deployment
- [ ] Application functionality verified
- [ ] Performance metrics within acceptable ranges
- [ ] Error rates normal
- [ ] Monitoring alerts not triggered
- [ ] Documentation updated
- [ ] Deployment recorded in change log

## 🔧 Maintenance Procedures

### Regular Maintenance Tasks

#### Weekly Tasks
```bash
# Check system health
./scripts/health-check.sh

# Review CloudWatch metrics
aws cloudwatch get-metric-statistics --namespace AWS/ECS
aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB
aws cloudwatch get-metric-statistics --namespace AWS/RDS

# Check for failed deployments
aws ecs list-services --cluster aws-infra-platform-cluster
```

#### Monthly Tasks
```bash
# Update container images with security patches
docker pull node:18-alpine
# Rebuild and deploy application

# Review and optimize costs
aws ce get-cost-and-usage \
    --time-period Start=2025-08-01,End=2025-08-31 \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE

# Database maintenance
aws rds describe-db-instances --db-instance-identifier aws-infra-platform-database
```

#### Quarterly Tasks
```bash
# Security audit
aws iam access-analyzer list-findings
aws config get-compliance-details-by-config-rule

# Performance optimization review
# Review ECS task sizing
# Analyze database performance metrics
# Optimize auto-scaling policies

# Disaster recovery testing
# Test