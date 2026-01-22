# Architecture Documentation & Decision Records (ADRs)

## Architecture Decision Records (ADRs)

This document records the architectural decisions made for the **FinTech Global Platform**.

| ID | Title | Status | Date |
|:---:|:---|:---:|:---|
| **ADR-001** | Use of **AWS Organizations** for Account Structure | Accepted | 2024-01-15 |
| **ADR-002** | Adoption of **ECS Fargate** for Compute | Accepted | 2024-01-16 |
| **ADR-003** | **Aurora PostgreSQL** as Primary Ledger | Accepted | 2024-01-16 |
| **ADR-004** | **DynamoDB** for Session Management | Accepted | 2024-01-17 |
| **ADR-005** | **Single Region Multi-AZ** High Availability Strategy | Accepted | 2024-01-18 |
| **ADR-006** | **Hub-and-Spoke VPC** Design | Accepted | 2024-01-18 |
| **ADR-007** | **AWS Secrets Manager** for Credential Rotation | Accepted | 2024-01-19 |
| **ADR-008** | **CloudWatch** & **X-Ray** for Observability Layer | Accepted | 2024-01-20 |
| **ADR-009** | **S3 Intelligent-Tiering** for Data Lake Storage | Accepted | 2024-01-21 |
| **ADR-010** | **Application Load Balancer** for Ingress | Accepted | 2024-01-22 |

---

### ADR-001: Use of AWS Organizations
*   **Context**: We need to manage multiple environments (Dev, Staging, Prod) and ensure strict security boundaries.
*   **Decision**: Implement a multi-account strategy using AWS Organizations with distinct OUs for Security, Infrastructure, and Workloads.
*   **Consequences**: Increases complexity of initial setup but provides superior billing isolation and security containment.

### ADR-002: Adoption of ECS Fargate
*   **Context**: The application requires container orchestration. We need to minimize operational overhead for patching the underlying OS.
*   **Decision**: Use **Amazon ECS with Fargate Launch Type**.
*   **Consequences**: Slightly higher cost per vCPU compared to raw EC2, but massive savings in engineering hours (no OS patching, bin packing, or agent management).

### ADR-003: Aurora PostgreSQL as Primary Ledger
*   **Context**: Financial transaction data requires ACID compliance, relational integrity, and point-in-time recovery.
*   **Decision**: Use **Amazon Aurora PostgreSQL Compatible Edition**.
*   **Consequences**: Provides 3x performance of standard PostgreSQL and 6-way storage replication across AZs automatically.

### ADR-004: DynamoDB for Session Management
*   **Context**: User sessions are high-velocity, ephemeral, and key-value based. Relation databases would suffer contention.
*   **Decision**: Use **Amazon DynamoDB** with TTL enabled.
*   **Consequences**: Delivers single-digit millisecond latency regardless of scale. Requires careful schema design (access patterns must be known).

### ADR-005: Single Region Multi-AZ Strategy
*   **Context**: Business requirement is 99.9% availability. Global replication adds complexity and cost not currently justified by the user base location.
*   **Decision**: Deploy to `us-east-1` utilizing **3 Availability Zones**.
*   **Consequences**: Protects against data center failures. Regional failure is a known risk accepted by the business at this stage.

### ADR-006: Hub-and-Spoke VPC Design
*   **Context**: We need to isolate workloads while offering shared services (like logging or inspection) where necessary.
*   **Decision**: VPCs for each environment, with strict subnets (Public/Private/Data).
*   **Consequences**: Requires NAT Gateways (cost implication) for private subnets to reach the internet for updates, but ensures maximum security.

### ADR-007: AWS Secrets Manager
*   **Context**: Hardcoded credentials are a major security risk.
*   **Decision**: Use **AWS Secrets Manager** with automatic rotation enabled for RDS and API keys.
*   **Consequences**: Application code must use AWS SDK to fetch secrets at runtime, separating config from code.

### ADR-008: Observability Layer
*   **Context**: Microservices architecture makes debugging difficult.
*   **Decision**: Standardize on **CloudWatch** for logs/metrics and **X-Ray** for distributed tracing.
*   **Consequences**: Tight integration with AWS ecosystem. Avoids the operational overhead of managing a third-party observability stack like Prometheus/Grafana.

### ADR-009: S3 Intelligent-Tiering
*   **Context**: Data Lake logs can grow indefinitely and access patterns are unpredictable.
*   **Decision**: Enable **S3 Intelligent-Tiering** for the Data Lake bucket.
*   **Consequences**: Automatically moves objects to lower-cost tiers when not accessed, optimizing costs without manual lifecycle rules complexity.

### ADR-010: ALBs for Ingress
*   **Context**: We need Layer 7 routing capabilities (path-based routing) for microservices.
*   **Decision**: Use **Application Load Balancers (ALB)**.
*   **Consequences**: Supports WAF integration and path-based routing, enabling blue/green deployments.

---

## 📐 Data Flow Architecture

### Transaction Processing Flow
1.  **Ingress**: User requests `POST /transaction` via HTTPS -> CloudFront -> ALB.
2.  **Compute**: ALB routes to `fintech-api` service in ECS Fargate.
3.  **Authentication**: API validates session token against **DynamoDB**.
4.  **Logic**: API logic executes, calculating fees/balances.
5.  **Persistence**:
    *   **Write**: Transaction committed to **Aurora PostgreSQL** (Writer).
    *   **Cache**: User balance updated in **Redis** (Invalidate/Set).
6.  **Audit**: Event logged to **CloudWatch Logs** asynchronously.

### Analytics Flow
1.  **Ingestion**: Aurora exports logs/snapshots to **S3 Data Lake**.
2.  **Processing**: Glue jobs (future) or Athena queries run against S3 data.
3.  **Reporting**: QuickSight consumes aggregated data from S3/Athena.
