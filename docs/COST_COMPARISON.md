# Cost Optimization Case Study & Comparison

Inspired by real-world strategies from **GeeksforGeeks**, this document outlines how we achieved up to **70% cost reductions** by shifting from fully managed services to optimized self-hosted alternatives where appropriate.

## 📉 The GeeksforGeeks Strategy

The DevOps team at GeeksforGeeks implemented three key changes that drastically reduced their AWS bill:

1.  **Self-Hosted Redis (60-70% Savings)**:
    *   *Problem*: Managed ElastiCache was expensive for their caching needs.
    *   *Solution*: Migrated to self-hosted Redis on EC2 instances.
    *   *Result*: Same performance with significantly lower costs.

2.  **Edge Caching (50-70% Savings)**:
    *   *Problem*: High bandwidth costs for serving educational videos.
    *   *Solution*: Aggressive CloudFront caching at edge locations (up to 1 year for static assets).
    *   *Result*: Reduced origin fetch costs and improved latency for users in India.

3.  **Automated Environment Shutdown (50% Savings)**:
    *   *Problem*: Dev/Test servers running 24/7 despite only being used during office hours.
    *   *Solution*: Simple Bash script + Cron job to stop servers at 10 PM and start at 9 AM.
    *   *Result*: Halved the compute hours for non-production environments.

---

## 🆚 Architecture Comparison

We offer two architectural patterns for this project: the "Standard Managed" (easier to maintain) and the "Cost-Optimized" (cheaper to run).

### Option A: Standard Managed (The "Peace of Mind" Choice)
*   **Best for**: Small teams, strict compliance needs, minimal DevOps capacity.
*   **Components**: Amazon ElastiCache, NAT Gateways, Always-on Fargate.
*   **Pros**: Zero maintenance, automatic patching, instant scalability.
*   **Cons**: Higher premium for "managed" convenience.

### Option B: Cost-Optimized (The "GeeksforGeeks" Choice)
*   **Best for**: Scale-ups, cost-sensitive projects, teams with Linux expertise.
*   **Components**: Redis on EC2, NAT Instances, Scheduled Shutdowns.
*   **Pros**: Maximum control, lowest possible infrastructure bill.
*   **Cons**: Requires manual patching and monitoring.

### 📊 Cost Breakdown (Estimated Monthly for 500k Users)

| Component | Standard Managed (Architecture A) | Cost-Optimized (Architecture B) | Savings |
|:---|:---|:---|:---:|
| **Caching** | ElastiCache Redis (Cluster Mode)<br>**$180/mo** | Redis on t4g.medium EC2<br>**$30/mo** | **83%** |
| **Compute** | Fargate (Always On)<br>**$400/mo** | EC2 Auto-Scaling + Nightly Shutdown<br>**$150/mo** | **62%** |
| **Data Transfer**| NAT Gateway (Processed Data)<br>**$200/mo** | NAT Instance (t4g.nano)<br>**$5/mo** | **97%** |
| **Content** | S3 Direct Access<br>**$100/mo** | CloudFront Aggressive Caching<br>**$40/mo** | **60%** |
| **Total** | **~$880 / month** | **~$225 / month** | **~74%** |

---

## 🛠️ Implementing the Solution

To switch to the **Cost-Optimized** architecture:

1.  **Deploy Redis on EC2**: Use the `t4g` instances (ARM-based) for better price/performance.
    ```bash
    # Install Redis on Amazon Linux 2023
    sudo dnf install -y redis6
    sudo systemctl enable redis6
    sudo systemctl start redis6
    ```

2.  **Automate Non-Prod Shutdown**:
    Use the included script `scripts/auto-shutdown.sh` in your crontab:
    ```bash
    0 22 * * * /scripts/auto-shutdown.sh stop
    0 9 * * 1-5 /scripts/auto-shutdown.sh start
    ```

3.  **Enable CloudFront Caching**:
    Set cache headers on your S3 objects to `Cache-Control: max-age=31536000` (1 year) for static files.

> **Note**: While Option B saves money, it increases operational responsibility. Ensure you have monitoring in place (Use CloudWatch Agent) to track disk space and memory on your self-hosted instances.
