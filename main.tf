terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  type        = string
  description = "AWS region"
  default     = "eu-west-1"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile"
  default     = "default"
}

# Bucket name must be globally unique — change this!
variable "bucket_name" {
  type        = string
  default     = "mimyrtek-s3-bucket"
  description = "mimyrtek-s3-bucket"
}

variable "dynamodb_table_name" {
  type        = string
  description = "mimyrtek-DynamoDB"
  default     = "tf-locks"
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.bucket_name
}

# Strongly recommended settings for a TF state bucket
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "backend" {
  value = {
    bucket          = aws_s3_bucket.tf_state.bucket
    dynamodb_table  = aws_dynamodb_table.locks.name
    region          = var.region
    recommended_key = "envs/dev/terraform.tfstate"
  }
}
