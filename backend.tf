terraform {
  backend "s3" {
    bucket         = "benjamin-demo-bucket-16165190"   # Must match the exact name
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
