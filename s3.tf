resource "aws_s3_bucket" "data_storage" {
  bucket = "${var.project_name}-data-storage-${var.environment}"

  tags = {
    Name = "${var.project_name}-data-storage"
  }
}

resource "aws_s3_bucket_versioning" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }

  rule {
    id     = "delete-incomplete-multipart"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE"]
    allowed_origins = ["https://${var.domain_name}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_notification" "data_storage" {
  bucket = aws_s3_bucket.data_storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf_processing.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/pdfs/"
    filter_suffix       = ".pdf"
  }

  depends_on = [aws_lambda_permission.s3_invoke_pdf_processing]
}

resource "aws_lambda_permission" "s3_invoke_pdf_processing" {
  statement_id  = "AllowExecutionFromS3"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf_processing.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.data_storage.arn
}
