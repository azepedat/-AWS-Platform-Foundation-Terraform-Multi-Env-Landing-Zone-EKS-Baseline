terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

locals {
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  vpc_name           = "${var.project_name}-${var.environment}"
  vpc_cidr           = "10.2.0.0/16"
  azs                = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  private_subnets    = ["10.2.10.0/24", "10.2.11.0/24", "10.2.12.0/24"]
  single_nat_gateway = false
  tags               = local.tags
}

module "kms" {
  source = "../../modules/kms"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.tags
}

module "iam" {
  source = "../../modules/iam"

  environment  = var.environment
  project_name = var.project_name
  tags         = local.tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name        = "${var.project_name}-${var.environment}"
  subnet_ids          = module.network.private_subnet_ids
  cluster_role_arn    = module.iam.cluster_role_arn
  node_role_arn       = module.iam.node_role_arn
  kms_key_arn         = module.kms.key_arn
  node_instance_types = ["t3.large"]
  node_desired_size   = 3
  node_min_size       = 2
  node_max_size       = 6
  tags                = local.tags
}

module "observability" {
  source = "../../modules/observability-prereqs"

  cluster_name            = module.eks.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  log_retention_days      = 365
  tags                    = local.tags
}