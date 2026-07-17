# Production Environment
# References the shared modules for production deployment

terraform {
  required_version = ">= 1.6.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
  }

  backend "s3" {
    bucket = "swiggy-gitops-tfstate-843998948464"
    key    = "prod/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "prod"
      Project     = "swiggy-gitops"
      ManagedBy   = "terraform"
    }
  }
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

module "eks" {
  source = "../../modules/eks"
  # Pass required variables for prod
}

module "ecr" {
  source = "../../modules/ecr"
  # Pass required variables for prod
}
