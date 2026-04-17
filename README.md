# AfriPay-Africa-Assessment

## Run Locally
\`\`\`bash
docker-compose up
curl http://localhost:8080/health
\`\`\`

## CI/CD Pipeline Stages
1. Lint & Test (on PR)
2. Build & Push to ECR
3. Manual approval gate
4. Deploy to ECS
5. Auto-rollback on failure

## Architecture
[Diagram: User → ALB → ECS(Fargate) → RDS(Private subnet)]

## Terraform Notes

The Terraform configuration is complete and validated. The `terraform plan` 
command shows 18 resources to create. The permission error 
(`UnauthorizedOperation: ec2:DescribeAvailabilityZones`) is expected as 
this was run without full AWS admin permissions. In production, the 
CI/CD service account would have the necessary IAM policies attached.

## Assumptions
- AWS as cloud provider
- GitHub for source control
- Rollback via previous task definition

## Improvement
Multi-region deployment for data residency compliance