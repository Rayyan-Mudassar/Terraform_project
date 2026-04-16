# Project 4 — AWS Infrastructure with Terraform & GitHub Actions CI/CD

## Overview

Provisioned a production-style AWS infrastructure using Terraform with a fully automated CI/CD pipeline via GitHub Actions. Infrastructure is deployed and managed entirely through code — no manual AWS Console clicks after initial setup.

---

## Architecture

```
GitHub Repo
    │
    ├── Pull Request  →  GitHub Actions triggers terraform plan
    └── Merge to main →  GitHub Actions triggers terraform apply
                                    │
                                    ▼
                            AWS Infrastructure
                            ├── VPC (custom, isolated network)
                            ├── Public Subnet
                            ├── Internet Gateway + Route Table
                            ├── Security Group (port 80/443 open, SSH locked to my IP)
                            └── EC2 Instance (Amazon Linux 2, Nginx via user_data)

Remote State
    └── S3 Bucket (state file) + native locking (use_lockfile = true)
```

---

## Infrastructure Details

| Resource | Details |
|---|---|
| VPC | Custom CIDR, DNS hostnames enabled |
| Subnet | Public subnet, auto-assigns public IP |
| Internet Gateway | Enables outbound + inbound internet access |
| Route Table | Routes all traffic (0.0.0.0/0) through IGW |
| Security Group | Port 80/443 open to world, SSH restricted to my IP only |
| EC2 | Amazon Linux 2, t3.micro, Nginx installed via user_data (no SSH needed) |
| Remote State | S3 backend with native locking (`use_lockfile = true`) |

---

## Terraform File Structure

```
project4/
├── main.tf          # VPC, subnet, IGW, route table, SG, EC2
├── variables.tf     # instance type, region
├── backend.tf       # S3 remote state configuration
└── .github/
    └── workflows/
        └── terraform.yml   # CI/CD pipeline
```

---

## CI/CD Pipeline Flow

```
Developer pushes branch → opens PR
        │
        ▼
GitHub Actions: terraform plan
  - Checks out code
  - Configures AWS credentials (from GitHub Secrets)
  - Runs terraform init
  - Runs terraform plan → output shown in PR

Developer reviews plan → merges to main
        │
        ▼
GitHub Actions: terraform apply
  - Runs terraform init
  - Runs terraform apply --auto-approve
  - Infrastructure is live
```

---

## GitHub Secrets Used

| Secret | Purpose |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key for GitHub Actions |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key for GitHub Actions |

> These are never stored in code. All sensitive values go through GitHub Secrets.

---

## Issues Faced & Lessons Learned

**1. AWS Credentials — Extra Space Bug**
GitHub Actions was failing on AWS authentication. Root cause: extra whitespace in the secret value when copying the access key. Removing the space fixed it.
Lesson: Always trim whitespace when pasting credentials into GitHub Secrets.

**2. Wrong AMI — Region Mismatch**
Initial `terraform apply` failed because the AMI ID was copied from a different region. AMI IDs are region-specific.
Lesson: Always grab the AMI ID from the correct region in the AWS Console, or use a `data` source to fetch it dynamically.

---

## Screenshots

### Pipeline — Terraform Apply on Merge
<img width="1600" height="855" alt="Screenshot (63)" src="https://github.com/user-attachments/assets/f7f1facc-2a4b-47a8-ba51-37a597497718" />

### Nginx Running in Browser (via EC2 Public IP)
<img width="1600" height="858" alt="Screenshot (64)" src="https://github.com/user-attachments/assets/e185d30a-d249-433f-a9eb-2ff21c82b83b" />

### Remote State in S3
<img width="1600" height="855" alt="Screenshot (65)" src="https://github.com/user-attachments/assets/a0d7e3af-8698-4969-b641-4140aa52bb8e" />


---

## How to Use

### Prerequisites
- Terraform installed
- AWS CLI configured
- An existing EC2 key pair in your target region
- An S3 bucket for remote state

### Steps

```bash
# Clone the repo
git clone https://github.com/Rayyan-Mudassar/Terraform_project

# Initialize Terraform (pulls providers, connects to remote state)
terraform init

# Preview changes
terraform plan

# Deploy
terraform apply

# Destroy when done
terraform destroy
```

---

## Rollback Strategy

Since infrastructure is version-controlled:

1. **Git revert** the bad commit
2. Push to main
3. Pipeline automatically runs `terraform apply` with the previous config
4. Infrastructure rolls back to last known good state

---

## Author

**Rayyan Mudassar** — Self-taught Cloud & Security Engineer  
[LinkedIn](https://www.linkedin.com/rayyan-mudassar/)
