provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "bucket1" {
  bucket = "swiggy-gitops-tfstate-843998948464"

  tags = {
    Name        = "swiggy-gitops-tfstate-843998948464"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "bucket1_versioning" {
  bucket = aws_s3_bucket.bucket1.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "bucket2" {
  bucket = "swiggy-gitops-tfstate-843998948464-prod"

  tags = {
    Name        = "swiggy-gitops-tfstate-843998948464-prod"
    Environment = "prod"
  }
}

resource "aws_s3_bucket_versioning" "bucket2_versioning" {
  bucket = aws_s3_bucket.bucket2.id
  versioning_configuration {
    status = "Enabled"
  }
}
