# Operational Runbooks

## 🚨 Incident Response & Operations Manual

This document outlines the standard operating procedures (SOPs) for maintaining the FinTech Global Platform.

---

## 📕 Runbook: Database Backup & Recovery

### 1. Automated Backups
*   **Aurora PostgreSQL**:
    *   **Frequency**: Continuous backup (Retention: 35 days).
    *   **Snapshots**: Daily system snapshots taken at 03:00 UTC.
    *   **Monitoring**: CloudWatch Alarm `BackupStorageBilling` monitors size.
*   **DynamoDB**:
    *   **PITR**: Point-In-Time Recovery is **ENABLED** (Retention: 35 days).

### 2. Manual Backup Procedure (Pre-Deployment)
Before any major schema change or deployment:
```bash
# Aurora Snapshot
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier fintech-cluster \
  --db-cluster-snapshot-identifier fintech-pre-deploy-$(date +%Y%m%d)

# DynamoDB Backup
aws dynamodb create-backup \
  --table-name fintech-sessions \
  --backup-name session-pre-deploy-$(date +%Y%m%d)
```

### 3. Restore Procedure (Disaster Recovery)
If data corruption occurs:

#### **Aurora Restore**
Time to Recovery (RTO): ~15-20 mins
```bash
# Restore to a new cluster (never overwrite existing in prod)
aws rds restore-db-cluster-to-point-in-time \
  --source-db-cluster-identifier fintech-cluster \
  --target-db-cluster-identifier fintech-cluster-recovery \
  --restore-to-time 2024-01-22T14:00:00Z
```
*Action*: Once verified, update the Route53 CNAME or Secret Manager to point to the new cluster endpoint.

#### **DynamoDB Restore**
Time to Recovery (RTO): ~10 mins
```bash
aws dynamodb restore-table-to-point-in-time \
  --source-table-name fintech-sessions \
  --target-table-name fintech-sessions-recovery \
  --restore-date-time 1705929600
```

---

## 📙 Runbook: Handling High Latency Alarms

**Trigger**: `HighLatency` Alarm > 500ms for 5 minutes.

1.  **Check Service Health**:
    *   Go to ECS Console -> Check for restarting tasks.
    *   Check CloudWatch Logs for "Connection Timeout" or "Memory Limit Exceeded".
2.  **Check Database Metrics**:
    *   Is Aurora CPU > 80%? If yes, check for long-running queries in Performance Insights.
    *   Is Redis Eviction count high? If yes, cache is thrashing. Upscale Redis cluster.
3.  **Remediation**:
    *   **Immediate**: If simple load spike, manually scale ECS service desired count +2.
    *   **Database**: If Aurora blocked, kill blocking PID via SQL.

---

## 📘 Runbook: Rotating Secrets

**Trigger**: Scheduled rotation failed or potential credential leak.

1.  **Immediate Rotation**:
    ```bash
    aws secretsmanager rotate-secret \
      --secret-id fintech/db-credentials
    ```
    *Note*: This triggers the Lambda rotator. Watch the execution logs.
2.  **Verify Application**:
    *   Check ECS logs to ensure the application picked up the new connection string (Application handles connection retry).

---

## 📗 Runbook: Scale-Out Event Validation

**Trigger**: Marketing campaign or surge expected.

1.  **Pre-warming (Optional)**:
    *   DynamoDB: Switch to On-Demand or increase provisioned capacity min limit.
    *   ECS: Update Auto Scaling Min Capacity.
    ```bash
    aws application-autoscaling register-scalable-target \
      --service-namespace ecs \
      --resource-id service/fintech-cluster/fintech-api-service \
      --min-capacity 10
    ```
2.  **Monitor**:
    *   Watch `WAF` dashboard for blocked requests (False positives).
    *   Watch `ALB` TargetResponseTime.

---

## 📞 Escalation Policy

| Severity | Response Time | Contact |
|:---:|:---:|:---|
| **P0 (Critical)** | 15 mins | SRE Team Pager, VP Engineering |
| **P1 (High)** | 1 hour | DevOps Lead |
| **P2 (Medium)** | 4 hours | On-Call Engineer |
| **P3 (Low)** | 24 hours | Jira Ticket |
