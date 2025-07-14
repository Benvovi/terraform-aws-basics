resource "aws_ecr_repository" "node_api_repo" {
  name                 = "node-api-repo"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "Node API Repo"
    Environment = "dev"
  }
}

output "ecr_repo_url" {
  value = aws_ecr_repository.node_api_repo.repository_url
}
