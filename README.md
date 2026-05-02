# ☁️ MyssTic Warden: Cloud Infrastructure (IaC)

![Status](https://img.shields.io/badge/Status-Active-green?style=flat-square)
![Terraform](https://img.shields.io/badge/IaC-Terraform-5835CC?style=flat-square&logo=terraform)
![AWS](https://img.shields.io/badge/Cloud-AWS-FF9900?style=flat-square&logo=amazon-aws)
![GitOps](https://img.shields.io/badge/Deployment-GitHub_Actions-2088FF?style=flat-square&logo=github-actions)

This repository contains the Infrastructure as Code (IaC) provisioning for the **MyssTic Warden** cloud environment, acting as the AWS backbone and production environment.

## 🏗️ Architecture & Security (Zero Trust)

Instead of relying on default cloud settings, this infrastructure is built from scratch with security and strict network boundaries in mind:

* **Networking:** Custom VPC (`10.0.0.0/16`), Public Subnet (`10.0.1.0/24`), and custom Route Tables.
* **Compute:** Debian 13 (Headless) running on a `t3.micro` instance.
* **Security Groups:** Default-deny inbound traffic. Only SSH (Port 22) is allowed.
* **State Management (Enterprise Grade):** Terraform state (`.tfstate`) is strictly managed via a **Remote Backend** using **Amazon S3** (object versioning, AES-256 encryption) and **DynamoDB** for concurrent state locking.

## 🗺️ Cloud Topology

```mermaid
graph TD
    classDef aws fill:#FF9900,stroke:#fff,stroke-width:2px,color:#000,font-weight:bold
    classDef tf fill:#5835CC,stroke:#fff,stroke-width:2px,color:#fff,font-weight:bold
    classDef cicd fill:#1a1b26,stroke:#e0af68,stroke-width:2px,color:#c0caf5
    classDef net fill:#292e42,stroke:#7aa2f7,stroke-width:2px,color:#c0caf5
    classDef compute fill:#16161e,stroke:#9ece6a,stroke-width:2px,color:#c0caf5

    GitHub((🐙 GitHub Actions)):::cicd -->|CI/CD Pipeline| TF[🟪 Terraform CLI]:::tf
    
    subgraph "Terraform Remote Backend"
        TF -.->|State Lock Mutex| Dynamo[(⚡ DynamoDB Table)]:::aws
        TF -.->|State Read/Write| S3[(🪣 S3 Bucket Encrypted)]:::aws
    end

    TF -->|Provisions via API| VPC[☁️ AWS Custom VPC]:::net

    subgraph "AWS us-east-2 Ohio"
        VPC --> IGW[🚪 Internet Gateway]:::net
        VPC --> Subnet[🌐 Public Subnet 10.0.1.0/24]:::net
        Subnet --> EC2[🖥️ Debian 13 t3.micro]:::compute
        Subnet --> SG[🛡️ Security Group SSH only]:::net
    end
```

## 🛠️ Tech Stack

* **Provisioning:** Terraform (HashiCorp)
* **Cloud Provider:** AWS (us-east-2)
* **State Backend:** AWS S3 + DynamoDB
* **CI/CD:** GitHub Actions
* **OS:** Debian Linux

## 🚀 Deployment Workflow (GitOps)

This repository enforces a GitOps workflow. Manual execution of `terraform apply` is deprecated for production environments.

1. **Continuous Deployment:** Any push to the `main` branch triggers the GitHub Actions pipeline.
2. The pipeline securely authenticates with AWS via injected Repository Secrets.
3. It automatically initializes the S3/DynamoDB backend, plans the infrastructure, and applies the changes.

*(For local testing and development only)*:
```bash
terraform init
terraform plan
terraform apply
```

> **Note:** The `terraform.tfstate` is excluded via `.gitignore` to prevent secret leakage. The absolute source of truth remains securely in AWS.

---
*Maintained by MyssTic Warden Cloud Operations.*
