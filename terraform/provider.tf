terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
  }
  # Remote state in S3 — shared between Jenkins and developers
  backend "s3" {
    bucket         = "cicd-demo-terraform-state-1771435510"
    key            = "cicd-demo/terraform.tfstate"
    region         = "ap-south-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
provider "aws" {
  region = var.aws_region
  # No credentials block needed!
  # Jenkins EC2 uses its attached IAM Role automatically.
}
