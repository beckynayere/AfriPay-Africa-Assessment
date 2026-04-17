# AfriPay Strategy Document

## Q1: Deployments across 6 markets
Use GitHub Actions + ArgoCD with per-market configuration.

## Q2: Rollback <5 minutes
Blue-green deployment + automated health checks.

## Q3: Risks of plaintext secrets
Exposure via config files, git history, breach of SSH access.

## Q4: Fix secrets
AWS Secrets Manager + IAM least privilege.

## Q5: Monitor before customers
Synthetic transactions from multiple African locations.

## Q6: 3 critical metrics
1. USSD session completion rate
2. P99 transaction latency
3. Database connection pool %

## Q7: Kenya peak load
Auto-scaling, read replicas, Redis caching.

## Q8: Test before 25th
k6 load tests with historical salary-date traffic.

## Q9: First priority
Automated deployments (prevents 3-hour Tanzania outage).
