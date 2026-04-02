# -------------------------------------------------------
# EKS Cluster (Control Plane)
# Purpose: The Kubernetes API server and etcd managed by AWS.
# You don't see or manage the master nodes - AWS handles that.
# -------------------------------------------------------
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  version  = var.cluster_version
  role_arn = var.cluster_role_arn

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  tags = var.tags
}

# -------------------------------------------------------
# Managed Node Group
# Purpose: The EC2 instances that run your pods.
# "Managed" means AWS handles provisioning, AMI updates,
# and draining nodes during upgrades.
# -------------------------------------------------------
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.subnet_ids
  instance_types  = var.node_instance_types

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  update_config {
    max_unavailable = 1
  }

  tags = var.tags
}

# -------------------------------------------------------
# EKS Add-ons
# Purpose: Core components every cluster needs.
# Managing them as add-ons means AWS handles upgrades
# instead of you manually applying YAML manifests.
# -------------------------------------------------------

# VPC CNI - Assigns pod IPs from VPC subnets.
# You know this one from K8s - it's what gives each pod a real VPC IP.
resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "vpc-cni"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# CoreDNS - Cluster DNS for service discovery.
# Resolves service names like "my-svc.default.svc.cluster.local"
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}

# kube-proxy - Maintains network rules on nodes for Service routing.
# Handles iptables/IPVS rules so Services work.
resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"

  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.main]
}