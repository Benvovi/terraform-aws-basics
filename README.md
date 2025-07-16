✅ Project Title: Deploy Node.js API on AWS ECS using Terraform

📁 Project Structure
bash
Copy
Edit
.
├── node-api-app/                   # Node.js application code
│   └── Dockerfile
├── terraform-app-infra/           # Terraform infrastructure code
│   ├── main.tf
│   ├── outputs.tf
│   ├── variables.tf
│   ├── backend.tf
│   ├── ecr.tf
│   ├── dynamodb.tf
│   └── versions.tf
├── .github/workflows/
│   └── terraform.yml              # GitHub Actions workflow for CI/CD
├── .gitignore
├── README.md                      # (This file)
🚀 What This Project Does

This project provisions a fully functional infrastructure on AWS using Terraform to deploy a simple Node.js API using ECS and Fargate. It includes:

A custom VPC with public subnets

An Application Load Balancer (ALB)

ECS Cluster and Task Definition

IAM roles and policies

An ECR repository for Docker image

DynamoDB table for state locking

GitHub Actions for CI/CD automation

⚙️ Technologies Used
Terraform

AWS (ECS, VPC, ALB, IAM, ECR, DynamoDB, S3)

Node.js

Docker

GitHub Actions


🛠️ Steps Performed

Infrastructure Setup (terraform-app-infra)
Created a custom VPC with two public subnets.

Created an internet gateway and a route table.

Provisioned security groups for the ALB and ECS tasks.

Created an Application Load Balancer to expose the app.

Provisioned ECS resources:

ECS Cluster

Task Definition for the Node.js app

ECS Service with Fargate launch type

IAM roles and policies for ECS task execution

Configured remote backend using:

S3 bucket for state storage

DynamoDB table for state locking

App Setup (node-api-app)
Created a simple Node.js app and Dockerfile.

Pushed the app to ECR using Docker.

GitHub Actions CI/CD (terraform.yml)
Automatically triggers on push to main.

Performs terraform init, validate, plan, and apply.

📦 Deployment Flow
Write and push Terraform files and Node.js app.

Workflow in .github/workflows/terraform.yml runs:

Initializes Terraform

Validates and applies infrastructure

App is deployed on ECS via Fargate and exposed via ALB.