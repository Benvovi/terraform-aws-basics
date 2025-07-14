 provider "aws" {
  region = "us-east-1"
}

# ─────────────────────────────────────────────
# VPC and Subnets
# ─────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.11.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "subnet_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.12.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
}

# ─────────────────────────────────────────────
# ECS Cluster
# ─────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

# ─────────────────────────────────────────────
# IAM Role for ECS Task Execution
# ─────────────────────────────────────────────
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────────
# ECS Task Definition
# ─────────────────────────────────────────────
resource "aws_ecs_task_definition" "node_api_task" {
  family                   = "node-api-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "node-api-container"
      image     = "537124959230.dkr.ecr.us-east-1.amazonaws.com/node-api-repo:v5"
      essential = true
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
        }
      ]
      environment = [
        {
          name  = "DEPLOYED_AT"
          value = "${timestamp()}"
        }
      ]
    }
  ])
}


# ─────────────────────────────────────────────
# SECURITY GROUP for ALB and ECS
# ─────────────────────────────────────────────
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow ECS app port"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "alb-security-group"
  }
}

# ─────────────────────────────────────────────
# APPLICATION LOAD BALANCER
# ─────────────────────────────────────────────
resource "aws_lb" "app_alb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [
    aws_subnet.subnet_a.id,
    aws_subnet.subnet_b.id
  ]

  tags = {
    Name = "app-lb"
  }

  depends_on = [aws_internet_gateway.gw]
}

# ─────────────────────────────────────────────
# TARGET GROUP
# ─────────────────────────────────────────────
resource "aws_lb_target_group" "app_tg" {
  name         = "app-tg"
  port         = 80
  protocol     = "HTTP"
  vpc_id       = aws_vpc.main.id
  target_type  = "ip" # ✅ REQUIRED for FARGATE / awsvpc

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "app-tg"
  }
}

# ─────────────────────────────────────────────
# ALB LISTENER
# ─────────────────────────────────────────────
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }

  depends_on = [aws_lb_target_group.app_tg]
}

# ─────────────────────────────────────────────
# ECS SERVICE
# ─────────────────────────────────────────────
resource "aws_ecs_service" "app_service" {
  name            = "node-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.node_api_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  # 👇 Add this line
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets = [
      aws_subnet.subnet_a.id,
      aws_subnet.subnet_b.id
    ]
    security_groups  = ["sg-0d164f30c0f8e8f55"]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "node-api-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.app_listener]
}

# ─────────────────────────────────────────────
# INTERNET GATEWAY
# ─────────────────────────────────────────────
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-internet-gateway"
  }
}

# ─────────────────────────────────────────────
# PUBLIC ROUTE TABLE
# ─────────────────────────────────────────────
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# ─────────────────────────────────────────────
# ROUTE TABLE ASSOCIATIONS
# ─────────────────────────────────────────────
resource "aws_route_table_association" "subnet_a_association" {
  subnet_id      = aws_subnet.subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "subnet_b_association" {
  subnet_id      = aws_subnet.subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}