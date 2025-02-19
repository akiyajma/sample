locals {
  backend_log_retention_expiration = 180
  backend_log_retention_glacier    = 30
}

#################
# terraform state bucket
#################
resource "aws_s3_bucket" "terraform_state" {
  bucket = "${local.product}-${local.env}-tf-state-file"

  tags = {
    Name = "${local.product}-${local.env}-tf-state-file"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  target_bucket = aws_s3_bucket.terraform_state_access_log.bucket
  target_prefix = "log/"
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    id = "rule1"
    expiration {
      # 10 years
      days = 3652
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#################
# terraform state access log bucket
#################
resource "aws_s3_bucket" "terraform_state_access_log" {
  bucket = "${local.product}-${local.env}-tf-state-access-log"

  tags = {
    Name = "${local.product}-${local.env}-tf-state-access-log"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_access_log" {
  bucket = aws_s3_bucket.terraform_state_access_log.bucket
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "terraform_state_access_log" {
  bucket = aws_s3_bucket.terraform_state_access_log.bucket

  rule {
    id = "rule1"
    transition {
      days          = local.backend_log_retention_glacier
      storage_class = "GLACIER"
    }
    expiration {
      days = local.backend_log_retention_expiration
    }
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state_access_log" {
  bucket                  = aws_s3_bucket.terraform_state_access_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_access_log" {
  bucket = aws_s3_bucket.terraform_state_access_log.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "terraform_state_access_log" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.terraform_state_access_log.arn}/*",
      aws_s3_bucket.terraform_state_access_log.arn
    ]
  }
  statement {
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.terraform_state_access_log.arn}/*",
      aws_s3_bucket.terraform_state_access_log.arn
    ]
  }
}

resource "aws_s3_bucket_policy" "terraform_state_access_log" {
  bucket = aws_s3_bucket.terraform_state_access_log.id
  policy = data.aws_iam_policy_document.terraform_state_access_log.json
}