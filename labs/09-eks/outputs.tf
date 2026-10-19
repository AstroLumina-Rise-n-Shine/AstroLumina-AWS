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
