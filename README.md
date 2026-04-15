AWS Multi-Environment Landing Zone with EKS

A production-ready, modular Terraform infrastructure that provisions dev/stage/prod environments on AWS with EKS clusters, encryption, IRSA, and centralized observability


Sections: 

1. Problem Statement
2. Architecture Overview
3. Tech Stack
4. Project Structure
5. Environment Configuration
6. Prerequisites + Deployment
7. Security Features
8. Key Design Decisions

---

Section 1: Problem Statement

A team needs a repeatable, secure AWS foundation that can spin up dev/stage/prod environments consistently, with guardrails and a standardized EKS baseline. Manual environment setup leads to drift, inconsistency, and security gaps

Section 2: Architecture Overview

┌─────────────────────────────────────────────────────┐
│                   S3 + DynamoDB                      │
│               (Remote State Backend)                 │
└──────────────┬──────────────┬──────────────┬────────┘
              │              │              │
       ┌──────▼──┐    ┌──────▼──┐    ┌──────▼──┐
       │   Dev   │    │  Stage  │    │   Prod  │
       └────┬────┘    └────┬────┘    └────┬────┘
            │              │              │
    ┌───────▼───────┐     ...           ...
    │  VPC (10.0)   │
    │  ├─ Public x3 │
    │  ├─ Private x3 │
    │  └─ NAT GW    │
    │  └─ IGW       │
    ├───────────────┤
    │  IAM Roles    │
    │  ├─ Cluster   │
    │  └─ Nodes     │
    ├───────────────┤
    │  KMS Key      │
    ├───────────────┤
    │  EKS Cluster  │
    │  ├─ Node Group│
    │  ├─ VPC CNI   │
    │  ├─ CoreDNS   │
    │  └─ kube-proxy│
    ├───────────────┤
    │  Observability│
    │  ├─ OIDC/IRSA │
    │  └─ CloudWatch│
    └───────────────┘


Section 3: Tech Stack

| Tool              |                 Purpose                       |
|-------------------|-----------------------------------------------|
| Terraform         | Infrastructure as Code                        |
| AWS EKS           | Managed Kubernetes                            |
| AWS VPC           | Network isolation per environment             |
| AWS KMS           | Encryption for K8s secrets at rest            |
| AWS IAM + IRSA    | Pod-level identity and least-privilege access |
| AWS S3 + DynamoDB | Remote state storage and locking              |
| AWS CloudWatch | Centralized logging                              |


Section 4: Project Structure

├── bootstrap/                  # S3 + DynamoDB for remote state
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── modules/
│   ├── network/               # VPC, subnets, NAT, routing
│   ├── iam/                   # EKS cluster + node IAM roles
│   ├── kms/                   # KMS encryption key
│   ├── eks/                   # EKS cluster, node group, add-ons
│   └── observability-prereqs/ # CloudWatch, OIDC provider, IRSA
├── envs/
│   ├── dev/                   # Dev environment config
│   ├── stage/                 # Stage environment config
│   └── prod/                  # Prod environment config
└── .gitignore


Section 5: Environment Comparison

Environment Configuration

| Setting                | Dev               | Stage            |         Prod       |
|------------------------|-------------------|------------------|--------------------|
| VPC CIDR               | 10.0.0.0/16       | 10.1.0.0/16      | 10.2.0.0/16        |
| NAT Gateways           | 1 (cost saving)   | 1 (cost saving)  | 3 (HA, one per AZ) |
| Node Instance          | t3.medium         | t3.medium        | t3.large           |
| Node Count             | 2 (min 1, max 3)  | 2 (min 1, max 4) | 3 (min 2, max 6)   |
| Log Retention          | 30 days           | 60 days          | 365 days           |
| K8s Secrets Encryption | KMS               | KMS              | KMS                |
 

Section 6: Environment Comparison

Environment Configuration

| Setting | Dev | Stage | Prod |
|---------|-----|-------|------|
| VPC CIDR | 10.0.0.0/16 | 10.1.0.0/16 | 10.2.0.0/16 |
| NAT Gateways | 1 (cost saving) | 1 (cost saving) | 3 (HA, one per AZ) |
| Node Instance | t3.medium | t3.medium | t3.large |
| Node Count | 2 (min 1, max 3) | 2 (min 1, max 4) | 3 (min 2, max 6) |
| Log Retention | 30 days | 60 days | 365 days |
| K8s Secrets Encryption | KMS | KMS | KMS |


Section 7: Prerequisites + How To Deploy

## Prerequisites

- Terraform >= 1.0
- AWS CLI with appropriate credential permissions
- kubectl

## Deployment 

### 1. Bootstrap Remote State
```bash
cd bootstrap
terraform init
terraform plan
terraform apply
```

### 2. Deploy an Environment
```bash
cd envs/dev
terraform init
terraform plan
terraform apply
```

### 3. Connect to cluster
```bash
aws eks update-config --region us-east-1 --name eks-dev-platform-dev
kubectl get nodes
````

Repeat steps 2 and 3 for stage and prod

Section 8: Security Features
## Security Features

- **Encryption at rest**: KMS key for K8s secrets, S3 state encryption
- **Network isolation**: Private subnets for EKS nodes, public subnets only for load balancers
- **IRSA**: Pod-level IAM roles instead of node-level (least privilege)
- **State locking**: DynamoDB prevents concurrent modifications
- **Public access blocked**: S3 bucket for state has all public access blocked


Section 9: Key Design Decisions

- **One module, multiple environments**: Same modules called with different parameters per env, reducing code duplication
- **Single NAT in dev/stage, multi-NAT in prod**: Balances cost vs availability
- **OIDC provider in observability module**: Enables IRSA for any future workload, not just CloudWatch
- **Remote state per environment**: Isolated state files prevent accidental cross-environment changes
- **Managed node groups over self-managed**: AWS handles AMI updates and node draining during upgrades