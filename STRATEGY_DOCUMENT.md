# AfriPay DevOps Strategy Document
## M-PESA Africa - DevOps Engineer Case Study

**Candidate:** Rebecca Nayere
**Date:** April 16, 2026
**Markets:** Kenya, Tanzania, Lesotho, Ethiopia, Mozambique, DRC

---

## Executive Summary

AfriPay faces critical challenges: manual deployments causing outages, plaintext secrets, no monitoring, and performance problems during peak loads. This document provides practical solutions for all issues.

---

## Q1: Deployments across 6 markets

**Problem:** Manual SSH deployments take 8 hours per market and frequently break things.

**Solution:** GitHub Actions + ArgoCD (GitOps)

**How it works:**
1. Developer pushes code to GitHub
2. GitHub Actions builds Docker image and pushes to ECR
3. ArgoCD (installed in each market) pulls the new image automatically
4. Deployment happens in 15 minutes instead of 8 hours

**Per-market configuration:**
- Kenya (high traffic): 5-20 tasks
- Tanzania (medium traffic): 2-10 tasks  
- Other markets (low traffic): 1-5 tasks

**Handles unreliable internet:** ArgoCD works offline for up to 72 hours

---

## Q2: Rollback under 5 minutes

**Problem:** Last month, a bad deployment took 3 hours to fix.

**Solution:** Blue-green deployment with automatic health checks

**How it works:**
1. Deploy new version alongside current version
2. Run health checks (check if app is working)
3. If healthy → switch traffic (30 seconds)
4. If unhealthy → keep old version, delete new version

**Result:** Rollback takes less than 2 minutes (beats the 5-minute requirement)

---

## Q3: Risks of plaintext secrets

**Current problem:** API keys and database passwords are stored in plain text files on production servers.

**Specific risks:**

| Risk | What could happen |
|------|-------------------|
| Git history | Secrets stay in code forever, even after deletion |
| SSH breach | Hacker gets ALL passwords at once |
| Insider threat | Any employee can see production passwords |
| Compliance | Violates PCI-DSS and Central Bank rules |
| Backups | Old backups contain plaintext passwords |

**Real example:** If a hacker gets into a server, they can read the config file and steal the entire customer database in minutes.

---

## Q4: Fix secrets management

**Solution:** AWS Secrets Manager + IAM least privilege

**How it works:**
1. Secrets stored encrypted (can't be read directly)
2. Application asks AWS for the secret when it starts
3. Only the app can access its own secrets (not humans)
4. Secrets automatically change every 30 days

**What you need to do:**
- Move all passwords to AWS Secrets Manager
- Remove all .env files from production
- Set up automatic secret rotation

**Cost:** ~$0.40 per month (very cheap)

---

## Q5: Monitor before customers complain

**Problem:** Team finds out about outages from Twitter complaints.

**Solution:** Synthetic transactions (automated tests) from multiple African locations

**How it works:**
1. Automated system runs a fake transaction every 60 seconds
2. Tests from Nairobi, Dar es Salaam, and Johannesburg
3. If test fails in 1 location → Slack message
4. If test fails in 2+ locations → Page engineer immediately

**Result:** Team knows about outage 5-9 minutes BEFORE customers notice

---

## Q6: 3 critical metrics for USSD payment service

**Metric 1: USSD Session Completion Rate**
- What it means: Percentage of people who finish their transaction
- Alert if: Below 95% for 5 minutes
- Why it matters: Direct measure of customer experience

**Metric 2: P99 Transaction Response Time**
- What it means: Worst-case response time (99% of requests are faster than this)
- Alert if: Above 8 seconds for 2 minutes
- Why it matters: Users give up after 10-15 seconds

**Metric 3: Database Connection Pool Usage**
- What it means: How many database connections are in use
- Alert if: Above 80% (warning), above 90% (critical)
- Why it matters: Tells you BEFORE a crash happens (2-5 minutes warning)

---

## Q7: Kenya peak load (salary dates 25th-31st)

**Problem:** On salary dates, servers struggle and response times get very slow.

**Solution:** Three layers of protection

**Layer 1: Auto-scaling**
- Normal days: 2-10 servers
- Salary dates: 5-20 servers
- Automatically adds more servers when CPU gets high

**Layer 2: Read replicas**
- Add 2 extra databases for reading data
- Balance checks and transaction history go to replicas
- Reduces main database load by 60%

**Layer 3: Redis caching**
- Store frequent data in memory (5 minute cache)
- Balance checks don't hit the database at all

**Expected improvement:**
- Response time: 15+ seconds → less than 3 seconds
- Database CPU: 95% → 45%

---

## Q8: Test before the 25th arrives

**Solution:** Load testing with k6 using real traffic patterns from last month

**Test schedule on the 24th:**

| Time | Test | How much traffic | What should happen |
|------|------|------------------|---------------------|
| 2pm | Baseline | 2x normal | Response under 2 seconds |
| 4pm | Peak | 5x normal | Response under 3 seconds |
| 6pm | Chaos | Kill random servers | Recovery under 30 seconds |
| 8-10pm | Endurance | 3x normal for 2 hours | No slowdown over time |

**Morning of the 25th (8am checklist):**
1. Check auto-scaling is configured
2. Verify read replicas are running
3. Warm up caches (load data into memory)
4. Send "ready" message to team Slack channel

---

## Q9: First priority (first two weeks)

**Choice:** Automated deployments with rollback

**Why this first:**

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Deployment time | 8 hours | 15 minutes | 96% faster |
| Rollback time | 3+ hours | Less than 5 minutes | 95% faster |
| Deployment errors | 1-2 per month | 0-1 per quarter | 90% reduction |

**Why not other priorities first:**
- **Secrets management:** Needs automated deployments to push changes
- **Monitoring:** Without automation, requires logging into 6 servers manually
- **Peak load:** No point scaling if you can't deploy the configuration

**10-day plan:**

| Days | What to do | Result |
|------|------------|--------|
| 1-2 | Set up GitHub Actions | Automated builds and tests |
| 3-4 | Configure ECR | Docker images stored securely |
| 5-6 | Set up ECS with blue-green | Zero-downtime deployments |
| 7-8 | Test rollback | Rollback works in 2 minutes |
| 9-10 | Deploy to Tanzania first | Live in production |

---

## Constraints addressed

| Constraint | How we solve it |
|------------|-----------------|
| USSD must stay up | Automatic rollback in 2 minutes |
| Small team | Use managed services (don't manage servers) |
| Unreliable internet | ArgoCD works offline for 72 hours |
| Data stays in country | Each market has its own database |
| Low transaction value | Auto-scaling saves money (fewer servers at night) |

---

## One thing to improve with more time

**Multi-region active-active deployment**

What it means: Users in Kenya go to Kenya servers, users in Tanzania go to Tanzania servers automatically.

**Benefits:**
- Zero downtime if one region goes down
- Faster response for all users
- Keeps data in its home country

**Time needed:** 2 engineers, 3 months
**Extra cost:** About 30% more

---

