# main.tf - Bootstrap resources for Terraform state management
# IMPORTANT: This module uses LOCAL state intentionally (chicken-egg problem)

#------------------------------------------------------------------------------
# S3 BUCKET - Stores Terraform state files
#------------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = false # Set to true in real production!
  }

  tags = {
    Name        = "Terraform State Bucket"
    Description = "Stores Terraform state files for ${var.project_name}"
  }
}

# Enable versioning - keeps history of state files
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption - state contains sensitive data
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access - state should never be public
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#------------------------------------------------------------------------------
# DYNAMODB TABLE - Provides state locking
#------------------------------------------------------------------------------

resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST" # No cost when not in use
  hash_key     = "LockID"          # Required by Terraform

  attribute {
    name = "LockID"
    type = "S" # S = String
  }

  tags = {
    Name        = "Terraform Lock Table"
    Description = "Prevents concurrent Terraform operations"
  }
}