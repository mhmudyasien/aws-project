# Why We Built It This Way

This document explains the "Big Decisions" behind the FinTech Global Platform.

## 🧠 Design Choices (ADRs)

| What we needed | What we chose | Why? |
|:---|:---|:---|
| **Account Structure** | **AWS Organizations** | To keep "Development" mistakes from breaking "Production". |
| **Running Code** | **ECS Fargate** | It manages the servers for us, so we don't have to patch Linux every week. |
| **Main Database** | **Aurora PostgreSQL** | It's faster than regular SQL and replicates data 6 times automatically. |
| **Session Data** | **DynamoDB** | It's incredibly fast (milliseconds) even with millions of users. |
| **High Availability** | **Multi-AZ (us-east-1)** | If one data center burns down, the bank stays open. |
| **Network Security** | **Hub-and-Spoke VPC** | Prevents databases from accidentally touching the public internet. |
| **Passwords** | **Secrets Manager** | No passwords are saved in the code. They rotate automatically. |
| **Monitoring** | **CloudWatch** | It's built-in giving us one place to look for logs and errors. |
| **Load Balancing** | **Application Load Balancer** | It understands web traffic and blocks hackers (WAF). |

---

## 📐 How Data Moves

### 1. When a User Pays (Transaction)
1.  **User** clicks "Pay" in the app.
2.  **Load Balancer** checks if the user is safe (WAF) and sends them to the **API**.
3.  **API** checks **DynamoDB** to see if the user is logged in.
4.  **API** writes the transaction to **Aurora** (The Ledger).
5.  **API** updates the balance in **Redis** (Cache) so the next page load is fast.

### 2. When We Check Reports (Analytics)
1.  **Aurora** sends data copies to **S3** (Storage) every night.
2.  **QuickSight** reads that data to make graphs for the CEO.
