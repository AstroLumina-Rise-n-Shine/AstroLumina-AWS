output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "API server endpoint of the EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "node_group_name" {
  description = "Name of the managed worker node group"
  value       = module.eks.node_group_name
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of the Cluster Autoscaler IRSA role to annotate on its Kubernetes service account (null when the autoscaler is disabled)"
  value       = module.eks.cluster_autoscaler_role_arn
}
