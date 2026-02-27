# Terraform EKS Cluster with CloudWatch Observability & Pod Identity

This repository deploys a fully functional Amazon EKS cluster with:

- VPC + private/public subnets
- EKS cluster (Terraform AWS module)
- Managed node groups
- EBS CSI driver (IRSA)
- CloudWatch Observability add-on
- EKS Pod Identity Agent add-on
- IAM Role for CloudWatch observability
- Pod Identity association for CloudWatch Agent
- Namespace and ServiceAccount for `cloudwatch-agent`

This setup is built to work in **AWS Sandbox / temporary training environments** where all resources are destroyed every day.  
No manual steps are required — everything is recreated through Terraform.

---

## 📦 Components deployed

### 🔹 EKS add-ons
| Add-on | Purpose |
|--------|---------|
| `eks-pod-identity-agent` | Required for Pod Identity authentication |
| `amazon-cloudwatch-observability` | Installs CloudWatch Agent + Container Insights |

### 🔹 IAM Role
An IAM role is automatically created through Terraform to allow the CloudWatch Agent to:

- publish metrics to CloudWatch
- fetch EC2 tags
- read EBS volumes metadata
- publish EMF logs

### 🔹 Kubernetes components
| Component | Namespace | Purpose |
|----------|-----------|---------|
| ServiceAccount `cloudwatch-agent` | amazon-cloudwatch | Identity for CloudWatch Agent add-on |
| Namespace `amazon-cloudwatch` | - | Required for CloudWatch Agent add-on |

### 🔹 Pod Identity Association
Terraform automatically links: