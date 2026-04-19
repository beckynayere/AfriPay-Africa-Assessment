# AfriPay-Africa-Assessment

# Health Check API - M-PESA DevOps Assessment

A production-grade health-check API built with Node.js and Express, demonstrating modern DevOps practices including containerization, CI/CD, infrastructure-as-code, and cloud deployment.

## Quick Start (Local Development)

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for local development)
- Git

### Run Locally with Docker Compose

```bash
# Clone the repository
git clone <https://github.com/beckynayere/AfriPay-Africa-Assessment>
cd <AfriPay-Africa-Assessment>

# Create .env file from example
cp .env.example .env

# Start all services (app + database + nginx)
docker-compose up -d

# Verify services are running
docker-compose ps

# Test the API
curl http://localhost/health
curl http://localhost/live
curl http://localhost/metrics

# View logs
docker-compose logs -f app
docker-compose logs -f postgres
docker-compose logs -f nginx

# Stop all services
docker-compose down

# Reset everything (including database)
docker-compose down -v
```

### Health Check Endpoints

- **GET /live** - Liveness probe (is the service running?)
  - Returns 200 if service is alive
  - Used by orchestrators for service restart decisions

- **GET /health** - Readiness probe (can the service accept requests?)
  - Returns 200 if healthy
  - Checks database connectivity
  - Used by load balancers to route traffic

- **GET /metrics** - Application metrics
  - Transaction count
  - Memory usage
  - Uptime

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT / LOAD BALANCER                    │
└────────────────────────┬────────────────────────────────────────┘
                         │ HTTP/HTTPS (Port 80/443)
                         ▼
        ┌────────────────────────────────────┐
        │      NGINX REVERSE PROXY            │
        │  - Rate Limiting                    │
        │  - Load Balancing                   │
        │  - SSL Termination                  │
        │  - Compression (gzip)               │
        └────────┬─────────────────────────────┘
                 │ Internal Network
        ┌────────┴──────────────────────────────────┐
        │                                           │
        ▼                                           ▼
   ┌─────────────┐                          ┌─────────────────┐
   │  Node.js    │                          │  PostgreSQL     │
   │  Express    │◄────────────────────────►│  Database       │
   │  App        │   Port 3000              │  Port 5432      │
   │  Container  │                          │  Container      │
   │             │                          │                 │
   │ Features:   │                          │ Features:       │
   │ - Health    │                          │ - Persistence   │
   │ - Metrics   │                          │ - Encryption    │
   │ - Logging   │                          │ - Backups       │
   │ - Graceful  │                          │ - Monitoring    │
   │   shutdown  │                          │                 │
   └─────────────┘                          └─────────────────┘
```

### Docker Compose Stack

```
┌─────────────────────────────────────────┐
│         Docker Compose Services          │
├─────────────────────────────────────────┤
│                                         │
│  1. nginx (Port 80)                    │
│     ├─ Reverse proxy                   │
│     ├─ Rate limiting                   │
│     └─ Health checks                   │
│                                         │
│  2. app (Port 3000, Internal)          │
│     ├─ Node.js 18 Alpine               │
│     ├─ Multi-stage Docker build        │
│     ├─ Non-root user (security)        │
│     └─ Health checks                   │
│                                         │
│  3. postgres (Port 5432, Internal)     │
│     ├─ PostgreSQL 15 Alpine            │
│     ├─ Persistent volume               │
│     ├─ Health checks                   │
│     └─ Auto-initialization (init.sql)  │
│                                         │
└─────────────────────────────────────────┘
```

## Part 1: Practical Assessment

### Task 1: Dockerization ✓

**Dockerfile:**
- Multi-stage build for minimal image size
- Alpine base image (~150MB vs 900MB with full Node)
- Non-root user for security
- Health checks configured
- Proper signal handling (dumb-init)

```bash
# Build the image
docker build -t healthcheck-api:latest .

# Run a container
docker run -p 3000:3000 healthcheck-api:latest
```

**Docker Compose:**
- Full local environment with app, database, and nginx
- Environment variables loaded from .env (no hardcoded secrets)
- Service dependencies with health checks
- Persistent database volume
- Isolated network

```bash
# Single command to start everything
docker-compose up -d
```

### Task 2: CI/CD Pipeline ✓

**GitHub Actions Workflow** (`.github/workflows/cicd.yml`)

**Pipeline Stages:**

1. **Lint & Test** (Stage 1)
   - Runs on every pull request
   - ESLint for code quality
   - Unit tests with Jest
   - Docker build test (dry run)

2. **Build & Push to ECR** (Stage 2)
   - Runs on push to main branch
   - Builds multi-stage Docker image
   - Tags with commit SHA
   - Pushes to Amazon ECR

3. **Security Scan** (Stage 3)
   - Trivy vulnerability scanner
   - Scans for critical/high vulnerabilities
   - Uploads results to GitHub Security tab

4. **Manual Approval Gate** (Stage 4)
   - ⭐ Requires human approval before production
   - GitHub Environments with status checks
   - Prevents accidental deployments

5. **Deploy to Production** (Stage 5)
   - Updates ECS service with new image
   - Force new deployment
   - Waits for service stabilization

6. **Verify Health** (Stage 6)
   - Checks /health endpoint
   - Retries up to 5 times
   - Fails if health check fails

7. **Auto-Rollback** (Stage 7) ⭐
   - Triggers ONLY on deployment failure
   - Gets previous task definition
   - Redeploys previous working version
   - **Completes in under 5 minutes**

8. **Notifications** (Stage 8)
   - Slack notifications on deployment status
   - Shows success, rollback, or failure



### Task 3: Infrastructure as Code ✓

**Terraform Configuration** (`/terraform`)

**AWS Infrastructure Created:**

```
VPC (10.0.0.0/16)
├── Public Subnets (2 AZs)
│   ├─ NAT Gateways
│   └─ Internet Gateway
├── Private Subnets (2 AZs)
│   ├─ ECS Cluster
│   ├─ Fargate Tasks
│   └─ Application Load Balancer
├── Database Subnets (2 AZs)
│   └─ RDS PostgreSQL
├── VPC Endpoints
│   ├─ ECR API
│   ├─ ECR DKR
│   ├─ CloudWatch Logs
│   └─ S3
└── Security Groups
    ├─ ALB
    ├─ ECS Tasks
    ├─ RDS
    └─ VPC Endpoints

IAM & Secrets
├── ECS Task Execution Role
├── ECS Task Role
├── EC2 Deployment Role
├── KMS Keys (RDS, Secrets, ECR)
└── AWS Secrets Manager (DB credentials)

Monitoring
├── CloudWatch Log Groups
├── CloudWatch Alarms
│   ├─ RDS CPU, Storage, Connections
│   ├─ ECS CPU
│   └─ ALB Target Health
└── Container Insights
```

**Security Best Practices:**
- ✅ No secrets hardcoded
- ✅ Secrets in AWS Secrets Manager (KMS encrypted)
- ✅ RDS encryption enabled
- ✅ IAM least privilege (no wildcards)
- ✅ Non-root container user
- ✅ Private subnets for databases
- ✅ VPC Endpoints to avoid NAT costs
- ✅ ALB for secure access

**Files:**
- `terraform/main.tf` - Core infrastructure (VPC, subnets, NAT)
- `terraform/security.tf` - IAM roles, security groups, KMS
- `terraform/database.tf` - RDS PostgreSQL with monitoring
- `terraform/ecs.tf` - ECS cluster, service, auto-scaling
- `terraform/variables.tf` - Input variables with validation
- `terraform/terraform.tfvars.example` - Example values

**Deploy:**
```bash
cd terraform

# Initialize Terraform
terraform init

# Review changes
terraform plan -var-file=terraform.tfvars

# Apply configuration
terraform apply -var-file=terraform.tfvars

# Get outputs
terraform output
```

### Task 4: README & Documentation ✓

This file! Includes:
- Quick start guide
- Architecture diagrams
- Setup instructions
- CI/CD pipeline explanation
- Infrastructure overview
- Assumptions & improvements
- Troubleshooting

## Part 2: AfriPay Case Study

See `STRATEGY_DOCUMENT.md` for the complete strategy document addressing:

1. **Deployments & Rollbacks** - Automated multi-market deployment with <5min rollback
2. **Secrets Management** - AWS Secrets Manager with KMS encryption
3. **Monitoring & Alerting** - Real-time alerts before customers notice
4. **Peak Load Handling** - Auto-scaling for salary date traffic spikes
5. **Priority Roadmap** - First-week focus areas

## Project Structure

```
├── .github/
│   └── workflows/
│       └── cicd.yml          # GitHub Actions CI/CD pipeline
├── terraform/
│   ├── main.tf                 # Core VPC and networking
│   ├── security.tf             # IAM, KMS, security groups
│   ├── database.tf             # RDS PostgreSQL
│   ├── ecs.tf                  # ECS, ALB, auto-scaling
│   ├── variables.tf            # Input variables
│   └── terraform.tfvars.example # Example variables
├── src/index.js                 # Express application
├── package.json                # Dependencies
├── Dockerfile                  # Multi-stage Docker build
├── docker-compose.yml          # Local development stack
├── nginx.conf                  # Reverse proxy configuration
├── init.sql                    # Database initialization
├── .eslintrc.json              # Code linting rules
├── server.test.js              # Unit tests
├── .env.example                # Environment variables template
└── README.md                   # This file
```

## Environment Variables

**Local Development** (`.env`):
```
NODE_ENV=development
PORT=3000
DB_HOST=postgres
DB_PORT=5432
DB_USER=devops
DB_PASSWORD=devops123
DB_NAME=healthcheck_db
```

**Production** (GitHub Actions Secrets):
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SLACK_WEBHOOK` (optional)

**RDS Credentials** (AWS Secrets Manager):
- Stored securely with KMS encryption
- Automatically injected into ECS tasks
- Never exposed in logs or code

## Testing

### Local Testing
```bash
# Install dependencies
npm install

# Run tests
npm test

# Run with coverage
npm test -- --coverage

# Lint code
npm run lint
```

### Docker Testing
```bash
# Test the Docker image
docker build -t test-image .
docker run -p 3000:3000 test-image

# Test endpoints
curl http://localhost:3000/live
curl http://localhost:3000/health
curl http://localhost:3000/metrics
```

### Load Testing
```bash
# Using Apache Bench
ab -n 1000 -c 10 http://localhost:80/health

# Using hey
hey -n 1000 -c 10 http://localhost:80/health

# Using k6
k6 run load-test.js
```

## Deployment Checklist

- [ ] Environment variables configured in GitHub secrets
- [ ] AWS credentials set up (Access Key + Secret Key)
- [ ] terraform.tfvars created with actual values
- [ ] Database password changed from default
- [ ] VPC CIDR blocks reviewed (no conflicts)
- [ ] ECR repository created
- [ ] ECS cluster capacity configured
- [ ] ALB health check path verified
- [ ] CloudWatch alarms configured with SNS/Slack
- [ ] RDS backup retention set appropriately

## Monitoring & Alerts

### CloudWatch Metrics Monitored:
- **RDS:** CPU, Storage, Connections, Latency
- **ECS:** CPU, Memory, Task Count, Deployment Status
- **ALB:** Request Count, Target Health, Response Time

### Recommended Alerting:
```
Metric              Threshold    Action
─────────────────────────────────────────
RDS CPU             > 80%        Scale up DB
RDS Storage         < 2GB        Increase storage
ECS CPU             > 90%        Auto-scale out
Unhealthy Targets   >= 1         Page on-call
API Response Time   > 1s         Investigate
Error Rate          > 1%         Alert ops
```

## Cost Optimization

**For Africa (Cost-Sensitive):**
- Use Fargate Spot instances (70% cheaper)
- RDS db.t3.micro for dev/staging
- Auto-scaling to 0 during off-hours
- Regional deployment (data residency)
- VPC Endpoints instead of NAT Gateway

**Estimated Monthly Cost (Production):**
- ECS Fargate: ~$50-100
- RDS db.t3.small: ~$30-50
- ALB: ~$15-20
- NAT Gateway: ~$30-40
- Data transfer: ~$10-20
- **Total: ~$135-230/month** (can be reduced with Spot)

## Security Considerations

### Container Security:
✅ Alpine base image (minimal attack surface)
✅ Non-root user
✅ No secrets in environment
✅ Health checks (SIGTERM handling)
✅ Read-only root filesystem (optional upgrade)

### Database Security:
✅ Encryption at rest (KMS)
✅ Encryption in transit (SSL)
✅ Private subnet (no internet)
✅ Security group restrictions
✅ Automated backups with encryption
✅ Deletion protection (production)

### Network Security:
✅ VPC with private subnets
✅ NAT Gateway for outbound
✅ ALB for ingress
✅ Security groups with least privilege
✅ VPC Endpoints (private connectivity)

### Secrets Management:
✅ AWS Secrets Manager
✅ KMS encryption
✅ Automatic rotation (optional)
✅ Audit logging
✅ No hardcoded credentials

## Assumptions & Trade-offs

### Assumptions Made:
1. **AWS is the target cloud** - Can be adapted for Azure, GCP
2. **Fargate for compute** - Reduces operational overhead vs EC2
3. **RDS for database** - Managed database for easier operations
4. **Single region** - Multi-region adds complexity
5. **Stateless application** - No session affinity required
6. **200GB/month traffic** - Estimated for health-check API
7. **Kenya primary market** - Can be scaled to 6 markets per case study

### Performance Trade-offs:
- RDS db.t3.micro: Good for demo, use t3.small+ for production
- Fargate CPU: 256 units (0.25 vCPU) - may need more for peak load
- ALB sticky sessions disabled - assumes stateless

### What I Would Improve With More Time:

1. **Multi-Region Deployment**
   - Deploy to Kenya, Tanzania, DRC regions
   - Cross-region RDS replication
   - Route53 health-based routing

2. **Kubernetes Upgrade**
   - EKS instead of ECS for better scalability
   - Helm charts for templating
   - ArgoCD for GitOps

3. **Advanced Monitoring**
   - Prometheus + Grafana
   - Distributed tracing (Jaeger)
   - APM (DataDog/NewRelic)

4. **Disaster Recovery**
   - Multi-AZ RDS failover testing
   - Cross-region backup strategy
   - Recovery time objectives (RTO/RPO)

5. **Cost Optimization**
   - Reserved Instances (1-year commitment)
   - Spot Instances for non-critical workloads
   - Right-sizing analysis

6. **Compliance & Audit**
   - Data residency per market (Kenya logs in Kenya)
   - PCI-DSS for payment data
   - SOC2 audit readiness
   - GDPR data export capability

7. **Load Testing**
   - k6 or JMeter load test scenarios
   - Capacity planning based on transaction volume
   - Scaling limits testing

8. **Backup & Recovery**
   - Automated backup testing
   - Disaster recovery drills
   - RTO/RPO documentation

## Troubleshooting

### Docker Issues

**Container won't start:**
```bash
docker-compose logs app
docker-compose ps
```

**Database connection failed:**
```bash
docker-compose exec postgres psql -U devops -d healthcheck_db
```

**Port already in use:**
```bash
# Change ports in docker-compose.yml
# Or kill existing container:
docker ps | grep healthcheck
docker kill <container-id>
```

### Terraform Issues

**State locked:**
```bash
terraform force-unlock <LOCK_ID>
```

**Resource already exists:**
```bash
terraform import aws_vpc.main vpc-xxxxx
```

**Plan shows unwanted changes:**
```bash
terraform refresh
terraform plan -out=tfplan
```

### Application Issues

**Health check failing:**
```bash
# Check database connectivity
curl http://localhost:3000/health
docker-compose logs postgres
```

**High memory usage:**
```bash
docker stats healthcheck-app
# Consider increasing ecs_task_memory in variables
```

**Slow response times:**
```bash
curl -w "@curl-format.txt" -o /dev/null -s http://localhost/metrics
# Check RDS performance insights
# Monitor ECS CPU/Memory
```

## Contributing

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make changes and test locally: `docker-compose up`
3. Run linting: `npm run lint`
4. Run tests: `npm test`
5. Push and create Pull Request
6. GitHub Actions will run CI pipeline
7. After approval, merge to main

## Next Steps

1. **Deploy locally** - `docker-compose up`
2. **Test endpoints** - `curl http://localhost/health`
3. **Review Terraform** - Check `terraform/main.tf`
4. **Deploy to AWS** - `terraform apply`
5. **Configure GitHub Actions** - Set AWS credentials
6. **Read case study** - See `STRATEGY_DOCUMENT.md`

## Resources

- [Docker Documentation](https://docs.docker.com)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions](https://github.com/features/actions)
- [AWS ECS Best Practices](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/best_practices.html)
- [Kubernetes vs ECS](https://www.youtube.com/watch?v=mD-DTBL9WtY)

---


**Assessment Deadline:** Monday, 20 April 2026, 10:30am

**Questions?** Refer to the strategy document or create an issue in the repository.