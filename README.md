# ☁️ MyssTic Warden: Cloud Infrastructure (IaC)

![Status](https://img.shields.io/badge/Status-Active-green?style=flat-square)
![Terraform](https://img.shields.io/badge/IaC-Terraform-5835CC?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?style=flat-square&logo=amazon-aws)
![PostgreSQL](https://img.shields.io/badge/Database-PostgreSQL-316192?style=flat-square&logo=postgresql)
![Serverless](https://img.shields.io/badge/Event--Driven-AWS_Lambda-FF9900?style=flat-square&logo=awslambda)
![GitOps](https://img.shields.io/badge/Deployment-GitHub_Actions-2088FF?style=flat-square&logo=github-actions)

This repository contains the Infrastructure as Code (IaC) provisioning for the **MyssTic Warden** cloud environment, acting as the AWS backbone and production environment.

## 🏗️ Architecture & Security (Tier-3 Zero Trust)

The infrastructure is strictly modularized (Networking, Compute, Database, Monitoring, DNS) and built from scratch with strict network boundaries, dynamic secrets, and event-driven observability:

* **Networking (Multi-AZ):** Custom VPC (`10.0.0.0/16`) divided into a Public DMZ (`10.0.1.0/24`) and fully isolated Private Subnets (`10.0.2.0/24`, `10.0.3.0/24`).DNS is managed natively via Amazon Route 53.
* **Compute:** Debian Linux running on an ARM64 Graviton instance (t4g.micro), strictly hardened via UFW and connected to a private Mesh VPN using Tailscale.
* **Persistence:** Amazon RDS (PostgreSQL 16) deployed exclusively within the Private Zone.
* **Zero Trust Security Groups:** Default-deny inbound traffic. EC2 only allows HTTP/HTTPS. The RDS database denies IP-based connections, authenticating traffic cryptographically via the EC2's Security Group identity.
* **DevSecOps Secrets:** Passwords are never hardcoded. Terraform dynamically generates cryptographic keys, injecting them into **AWS Secrets Manager**.
* **Event-Driven Observability:** Automated Chaos/Failure detection. **Amazon CloudWatch** monitors EC2 metrics and triggers an **Amazon SNS** topic upon anomalies.
* **Serverless Alerting:** An **AWS Lambda** function (Python 3.12) subscribes to the SNS topic, processes the incident, and pushes real-time critical alerts to a Telegram Bot via API.
* **State Management (Enterprise Grade):** Terraform state (`.tfstate`) is strictly managed via a **Remote Backend** using **Amazon S3** (object versioning, AES-256 encryption) and **DynamoDB** for concurrent state locking.

## 🗺️ Cloud Topology

```mermaid
graph TD
    classDef aws fill:#FF9900,stroke:#fff,stroke-width:2px,color:#000,font-weight:bold
    classDef tf fill:#5835CC,stroke:#fff,stroke-width:2px,color:#fff,font-weight:bold
    classDef cicd fill:#1a1b26,stroke:#e0af68,stroke-width:2px,color:#c0caf5
    classDef net fill:#292e42,stroke:#7aa2f7,stroke-width:2px,color:#c0caf5
    classDef compute fill:#16161e,stroke:#9ece6a,stroke-width:2px,color:#c0caf5
    classDef db fill:#336791,stroke:#fff,stroke-width:2px,color:#fff,font-weight:bold
    classDef sec fill:#cc2222,stroke:#fff,stroke-width:2px,color:#fff,font-weight:bold
    classDef serverless fill:#D18B00,stroke:#fff,stroke-width:2px,color:#fff,font-weight:bold

    GitHub((🐙 GitHub Actions)):::cicd -->|CI/CD Pipeline| TF[🟪 Terraform CLI]:::tf
    
    subgraph "Terraform Remote Backend"
        TF -.->|State Lock Mutex| Dynamo[(⚡ DynamoDB Table)]:::aws
        TF -.->|State Read/Write| S3[(🪣 S3 Bucket Encrypted)]:::aws
    end

    TF -->|Provisions via API| VPC[☁️ AWS Custom VPC 10.0.0.0/16]:::net
    TF -->|Generates Password| Vault[🔐 AWS Secrets Manager]:::sec

    subgraph "AWS us-east-2 Ohio"
        Route53((🌐 Route 53)):::aws --> IGW
        VPC --> IGW[🚪 Internet Gateway]:::net
        
        subgraph "Public Zone (DMZ)"
            IGW --> PubSub[🌐 Public Subnet 10.0.1.0/24]:::net
            PubSub --> EC2[🖥️ t4g.micro Graviton]:::compute
            PubSub --> SG1[🛡️ SG: HTTP/HTTPS]:::net
        end

        subgraph "Private Zone (The Vault)"
            EC2 -->|Port 5432 / SG Auth| RDS[(🐘 RDS PostgreSQL)]:::db
            RDS -.-> PrivSub1[🔒 Subnet A 10.0.2.0/24]:::net
            RDS -.-> PrivSub2[🔒 Subnet B 10.0.3.0/24]:::net
            SG2[🛡️ SG: EC2 Identity Only]:::net -.-> RDS
        end
        
        subgraph "Event-Driven Observability"
            EC2 -.->|CPU Metrics| CW((👁️ CloudWatch Alarm)):::aws
            CW -->|Triggers| SNS[📻 SNS Topic]:::aws
            SNS -->|Invokes| Lambda[⚡ Lambda Python]:::serverless
        end
    end
    
    Lambda -->|API POST| Telegram((📱 Telegram Bot)):::cicd
```

## 🛠️ Tech Stack

* **Provisioning:** Terraform (HashiCorp) - Modular Architecture
* **Config Management:** Ansible (Roles structure)
* **Cloud Provider:** AWS (us-east-2)
* **Database:** Amazon RDS (PostgreSQL)
* **Serverless:** AWS Lambda, Amazon SNS, CloudWatch
* **Security:** AWS Secrets Manager, IAM, Tailscale VPN
* **State Backend:** AWS S3 + DynamoDB
* **CI/CD:** GitHub Actions
* **OS:** Debian Linux

## 🚀 Deployment Workflow (GitOps)

This repository enforces a GitOps workflow. Manual execution of `terraform apply` is deprecated for production environments.

1. **Continuous Deployment:** Any push to the `main` branch triggers the GitHub Actions pipeline.
2. The pipeline securely authenticates with AWS via injected Repository Secrets (including API Tokens).
3. It automatically initializes the S3/DynamoDB backend, plans the infrastructure, and applies the changes.

*(For local testing and development only)*:
```bash
terraform init
terraform plan -var-file="secret.tfvars"
terraform apply -var-file="secret.tfvars"
```

> **Note:** The secret.tfvars and .tfstate files are strictly excluded via .gitignore to prevent secret leakage. The absolute source of truth remains securely in AWS.

---
*Maintained by MyssTic Warden Cloud Operations.*