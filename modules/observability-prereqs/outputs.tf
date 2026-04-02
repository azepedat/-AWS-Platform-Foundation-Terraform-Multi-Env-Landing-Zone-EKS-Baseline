output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.eks.arn
}

output "cloudwatch_agent_role_arn" {
  description = "IAM role ARN for CloudWatch agent (annotate K8s ServiceAccount with this)"
  value       = aws_iam_role.cloudwatch_agent.arn
}

output "cluster_log_group_name" {
  description = "CloudWatch log group for cluster logs"
  value       = aws_cloudwatch_log_group.eks_cluster.name
}

output "application_log_group_name" {
  description = "CloudWatch log group for application logs"
  value       = aws_cloudwatch_log_group.eks_application.name
}