# Development Environment
# References the shared modules for dev deployment

terraform {
  required_version = ">= 1.6.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.25.0"
    }
  }

  backend "s3" {
    bucket = "swiggy111"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = "dev"
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

module "vpc" {
  source = "../../modules/vpc"
  # Pass required variables for dev
}

module "ec2_jumphost" {
  source = "../../modules/ec2-jumphost"
  # Pass required variables for dev
}

module "eks" {
  source = "../../modules/eks"
  # Pass required variables for dev
}

module "ecr" {
  source = "../../modules/ecr"
  # Pass required variables for dev
}

module "s3_backend" {
  source = "../../modules/s3-backend"
  # Pass required variables for dev
}
