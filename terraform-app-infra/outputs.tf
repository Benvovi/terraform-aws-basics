output "ecs_cluster_name" {
  description = "The ECS Cluster Name"
  value       = aws_ecs_cluster.main.name
}
