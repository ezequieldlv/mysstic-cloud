# ☁️ MyssTic Warden: Cloud Infrastructure (IaC)

This repository contains the Infrastructure as Code (IaC) provisioning for the **MyssTic Warden** cloud environment, acting as the AWS backbone for my Site Reliability Engineering (SRE) portfolio.

## 🏗️ Architecture & Security (Zero Trust)

Instead of relying on default cloud settings, this infrastructure is built from scratch with security and strict network boundaries in mind:

* **Networking:** Custom VPC (`10.0.0.0/16`), Public Subnet (`10.0.1.0/24`), and custom Route Tables.
* **Compute:** Debian 13 (Headless) running on a `t3.micro` instance.
* **Security Groups:** Default-deny inbound traffic. Only SSH (Port 22) is allowed.
* **State Management:** Terraform state (`.tfstate`) is strictly managed via a **Remote Backend** using Amazon S3 with object versioning and AES-256 native encryption.

## 🛠️ Tech Stack

* **Provisioning:** Terraform
* **Cloud Provider:** AWS (us-east-2)
* **OS:** Debian Linux

## 🚀 Deployment Workflow

To deploy this infrastructure, you need AWS CLI configured with proper IAM permissions.
```bash
# 1. Initialize Terraform and configure the S3 remote backend
terraform init

# 2. Review the execution plan
terraform plan

# 3. Apply the infrastructure
terraform apply
```

> **Note:** The `terraform.tfstate` is excluded via `.gitignore` to prevent secret leakage. The source of truth remains securely in AWS S3.