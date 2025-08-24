# AWS Infrastructure Platform with CI/CD

Enterprise-grade 3-tier web application with automated deployment pipeline.

## Architecture

- **Load Balancer**: AWS Application Load Balancer
- **Application**: Node.js API on ECS Fargate
- **Database**: RDS MySQL with automated backups
- **CI/CD**: GitHub Actions with automated deployments

## Features

- ✅ Infrastructure as Code (Terraform)
- ✅ Containerized applications (Docker)
- ✅ Automated deployments (GitHub Actions)
- ✅ Database connectivity and health checks
- ✅ Production monitoring and logging

## Quick Start

1. Clone repository
2. Configure AWS credentials
3. Deploy infrastructure: `terraform apply`
4. Push code changes for automated deployment

## Live Application

Visit: http://aws-infra-platform-alb-507901664.us-east-1.elb.amazonaws.com