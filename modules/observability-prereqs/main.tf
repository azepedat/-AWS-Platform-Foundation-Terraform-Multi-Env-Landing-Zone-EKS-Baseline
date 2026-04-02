# -------------------------------------------------------
# CloudWatch Log Groups
# Purpose: Centralized log storage for EKS.
# Separate groups for cluster logs vs application logs
# so you can set different retention and access policies.
# -------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "eks_application" {
  name              = "/aws/eks/${var.cluster_name}/application"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# -------------------------------------------------------
# OIDC Provider
# Purpose: Enables IRSA (IAM Roles for Service Accounts).
# This is the trust bridge between K8s and IAM.
# Without this, you'd have to give ALL pods on a node
# the same IAM permissions via the node role.
# With IRSA, each pod gets only the permissions it needs.
# -------------------------------------------------------
data "tls_certificate" "eks" {
  url = var.cluster_oidc_issuer_url
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = var.cluster_oidc_issuer_url
  tags            = var.tags
}

# -------------------------------------------------------
# CloudWatch Agent IRSA Role
# Purpose: An IAM role that only the cloudwatch-agent
# ServiceAccount can assume. This follows least-privilege -
# only the monitoring pod gets CloudWatch write access,
# not every pod on the node.
# -------------------------------------------------------
locals {
  oidc_provider_arn = aws_iam_openid_connect_provider.eks.arn
  oidc_provider_id  = replace(var.cluster_oidc_issuer_url, "https://", "")
}

resource "aws_iam_role" "cloudwatch_agent" {
  name = "${var.cluster_name}-cloudwatch-agent"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = local.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_provider_id}:aud" = "sts.amazonaws.com"
            "${local.oidc_provider_id}:sub" = "system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cloudwatch_agent.name
}