# System Architecture Documentation

## 🏗️ AWS Infrastructure Platform Architecture

### Overview
This document outlines the architecture of our enterprise-grade 3-tier web application platform built on AWS with full Infrastructure as Code automation.

## 🎯 Architecture Principles

### Design Goals
- **High Availability**: Multi-AZ deployment with automatic failover
- **Scalability**: Auto-scaling containers and database read replicas
- **Security**: Network isolation and least-privilege access
- **Maintainability**: Infrastructure as Code with Terraform
- **Cost Optimization**: Pay-per-use serverless containers

### Architecture Patterns
- **3-Tier Architecture**: Separation of presentation, application, and data layers
- **Microservices Ready**: Container-based architecture supports service decomposition  
- **Infrastructure as Code**: Complete automation and version control
- **Blue-Green Deployments**: Zero-downtime deployment strategy
- **Circuit Breaker**: Health checks and automatic recovery

## 🌐 Network Architecture

### VPC Design
```
AWS Region: us-east-1
VPC CIDR: 10.0.0.0/16

Availability Zones: us-east-1a, us-east-1b
├── Public Subnets (Internet Gateway)
│   ├── 10.0.1.0/24 (us-east-1a) - ALB, NAT Gateway
│   └── 10.0.2.0/24 (us-east-1b) - ALB, NAT Gateway
├── Private Subnets (NAT Gateway)
│   ├── 10.0.10.0/24 (us-east-1a) - ECS Containers
│   └── 10.0.20.0/24 (us-east-1b) - ECS Containers
└── Database Subnets (Isolated)
    ├── 10.0.100.0/24 (us-east-1a) - RDS Primary
    └── 10.0.200.0/24 (us-east-1b) - RDS Standby
```

### Routing Configuration
- **Internet Gateway**: Provides internet access to public subnets
- **NAT Gateways**: Enable internet access for private subnets (outbound only)
- **Route Tables**: Separate routing for each subnet tier
- **Network ACLs**: Additional network-level security controls

## 🔒 Security Architecture

### Network Security
```
Security Group Layers:
┌─────────────────────────────────────────────────────────┐
│ Internet → ALB Security Group (Port 80/443)            │
│   ├── Source: 0.0.0.0/0                               │
│   └── Protocols: HTTP/HTTPS                           │
└─────────────────────────────────────────────────────────┘
         │
┌─────────────────────────────────────────────────────────┐
│ ALB → ECS Security Group (Port 80)                     │
│   ├── Source: ALB Security Group                      │
│   └── Protocol: HTTP                                  │
└─────────────────────────────────────────────────────────┘
         │
┌─────────────────────────────────────────────────────────┐
│ ECS → RDS Security Group (Port 3306)                   │
│   ├── Source: ECS Security Group                      │
│   └── Protocol: MySQL                                 │
└─────────────────────────────────────────────────────────┘
```

### Data Security
- **Encryption at Rest**: RDS encryption with AWS KMS
- **Encryption in Transit**: SSL/TLS for all communications
- **Secrets Management**: AWS Secrets Manager for database credentials
- **IAM Roles**: Service-to-service authentication without credentials

## 🚀 Application Architecture

### Container Platform
```
ECS Fargate Cluster: aws-infra-platform-cluster
├── Service: web-app
│   ├── Task Definition: aws-infra-platform-task:6
│   ├── Desired Count: 1-10 (auto-scaling)
│   ├── CPU: 512 units (0.5 vCPU)
│   ├── Memory: 1024 MB
│   └── Network: awsvpc mode
└── Auto Scaling Policies
    ├── CPU Target: 70%
    └── Memory Target: 80%
```

### Application Stack
```
Container: aws-infra-platform-container
├── Base Image: node:18-alpine
├── Application: Express.js API
├── Port: 80
├── Health Check: GET /
└── Environment Variables:
    ├── NODE_ENV: dev
    ├── DB_HOST: aws-infra-platform-database.xxx.rds.amazonaws.com
    ├── DB_USER: admin
    ├── DB_NAME: webapp
    ├── DB_PORT: 3306
    └── DB_PASSWORD: <from Secrets Manager>
```

## 🗄️ Data Architecture

### Database Configuration
```
RDS MySQL 8.0
├── Instance Class: db.t3.micro
├── Storage: 20GB GP2 (General Purpose SSD)
├── Multi-AZ: Yes (High Availability)
├── Backup Retention: 7 days
├── Backup Window: 03:00-04:00 UTC
├── Maintenance Window: Sun 04:00-05:00 UTC
├── Encryption: Yes (AWS KMS)
└── Performance Insights: Disabled (t3.micro limitation)
```

### Database Connectivity
```
Connection Flow:
ECS Container → Private Subnet → Database Subnet → RDS Instance
├── Connection String: mysql://user:pass@host:3306/database
├── Connection Pool: MySQL2 driver default pool
├── Health Checks: Database ping every 30 seconds
└── Error Handling: Automatic reconnection with exponential backoff
```

## ⚖️ Load Balancing Architecture

### Application Load Balancer
```
ALB: aws-infra-platform-alb
├── Scheme: internet-facing
├── IP Address Type: IPv4
├── Subnets: Public subnets (multi-AZ)
├── Security Groups: alb-security-group
└── Target Group: aws-infra-platform-tg
    ├── Protocol: HTTP
    ├── Port: 80
    ├── Health Check Path: /
    ├── Health Check Interval: 30 seconds
    ├── Healthy Threshold: 3 consecutive successes
    ├── Unhealthy Threshold: 2 consecutive failures
    └── Timeout: 5 seconds
```

### Traffic Flow
```
Internet Traffic Flow:
User Request → Route 53 (Future) → ALB → ECS Target Group → Healthy Containers
│
├── Health Check: ALB → Container:80 → / endpoint
├── Load Balancing: Round robin across healthy targets
├── Session Persistence: None (stateless application)
└── SSL Termination: ALB level (Future HTTPS implementation)
```

## 🔄 Deployment Architecture

### Container Registry
```
ECR Repository: aws-infra-platform-app
├── Repository URI: 746669200695.dkr.ecr.us-east-1.amazonaws.com/aws-infra-platform-app
├── Image Scanning: Enabled
├── Tag Immutability: Mutable
└── Lifecycle Policy: Latest 10 images retained
```

### Deployment Strategy
```
Rolling Deployment Process:
1. Build new container image
2. Push to ECR repository
3. Update ECS task definition
4. Start new containers (desired count)
5. Health check new containers
6. Route traffic to healthy new containers
7. Drain and stop old containers
8. Complete deployment
```

## 📊 Monitoring Architecture

### CloudWatch Integration
```
Log Groups:
├── /ecs/aws-infra-platform (Container logs)
├── /aws/elasticloadbalancing/aws-infra-platform (ALB logs)
└── /aws/rds/instance/aws-infra-platform-database (Database logs)

Metrics:
├── ECS: CPU, Memory, Task count
├── ALB: Request count, Response time, Error rate
└── RDS: Connections, CPU, Storage
```

### Health Monitoring
```
Health Check Endpoints:
├── / (Basic application health)
└── /api/health (Database connectivity)

Response Format:
{
  "status": "healthy|unhealthy",
  "timestamp": "ISO 8601",
  "services": {
    "database": "connected|disconnected"
  }
}
```

## 🔧 Infrastructure as Code

### Terraform Architecture
```
Terraform Configuration:
├── main.tf (Core infrastructure: VPC, networking)
├── ecs.tf (Container orchestration)
├── alb.tf (Load balancer configuration)  
├── rds.tf (Database configuration)
├── variables.tf (Input parameters)
├── outputs.tf (Infrastructure outputs)
└── terraform.tfvars (Environment values)
```

### Resource Dependencies
```
Dependency Graph:
VPC → Subnets → Security Groups → RDS + ALB + ECS
├── Internet Gateway → Public Subnets → NAT Gateways → Private Subnets
├── Database Subnets → DB Subnet Group → RDS Instance
├── Public Subnets → ALB → Target Group → ECS Service
└── Private Subnets → ECS Service → Task Definition → ECR Repository
```

## 🎯 Scalability Architecture

### Horizontal Scaling
```
Auto Scaling Configuration:
├── Service Auto Scaling
│   ├── Min Capacity: 1
│   ├── Max Capacity: 10
│   ├── Target Tracking: CPU 70%, Memory 80%
│   └── Scale Out: 1 container per 2 minutes
├── Database Scaling (Future)
│   ├── Read Replicas: Up to 5
│   ├── Connection Pooling: PgBouncer/ProxySQL
│   └── Caching Layer: ElastiCache Redis
└── Load Balancer Scaling
    └── ALB: Automatically scales to handle traffic
```

### Performance Optimization
```
Optimization Strategies:
├── Container Optimization
│   ├── Multi-stage Docker builds
│   ├── Alpine Linux base images
│   └── Node.js process optimization
├── Database Optimization
│   ├── Connection pooling
│   ├── Query optimization
│   └── Indexing strategy
└── Caching Strategy (Future)
    ├── Application-level caching
    ├── CDN for static assets
    └── Database query caching
```

## 🛡️ Disaster Recovery Architecture

### High Availability Design
```
HA Components:
├── Multi-AZ Deployment
│   ├── ALB: Cross-AZ load balancing
│   ├── ECS: Tasks distributed across AZs
│   └── RDS: Multi-AZ with automatic failover
├── Auto Recovery
│   ├── ECS: Automatic task replacement
│   ├── ALB: Health check based routing
│   └── RDS: Automated backup and point-in-time recovery
└── Monitoring & Alerting
    ├── CloudWatch Alarms
    ├── SNS Notifications (Future)
    └── Automated incident response
```

### Backup Strategy
```
Backup Architecture:
├── Database Backups
│   ├── Automated daily backups
│   ├── 7-day retention period
│   ├── Point-in-time recovery
│   └── Cross-region replication (Future)
├── Infrastructure Backups
│   ├── Terraform state in S3 (Future)
│   ├── Configuration versioning
│   └── Infrastructure snapshots
└── Application Backups
    ├── Container images in ECR
    ├── Source code in Git
    └── Configuration management
```

---

## 📈 Future Architecture Enhancements

### Planned Improvements
- **HTTPS/SSL**: SSL certificate management with ACM
- **Domain Management**: Custom domain with Route 53
- **CDN**: CloudFront distribution for static assets
- **Caching**: Redis cluster for session and data caching
- **Monitoring**: Enhanced monitoring with Grafana dashboards
- **CI/CD**: Complete GitHub Actions automation
- **Multi-Environment**: Separate dev/staging/production environments

### Microservices Evolution
- **Service Mesh**: AWS App Mesh for service-to-service communication
- **API Gateway**: Centralized API management and rate limiting
- **Event-Driven**: SQS/SNS for asynchronous communication
- **Serverless**: Lambda functions for background processing

---

*Architecture Documentation - AWS Infrastructure Platform*  
*Last Updated: August 2025*  
*Version: 1.0*