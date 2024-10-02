resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-serverless-src-and-dest"
}

resource "aws_s3_bucket_ownership_controls" "bucketOwnershipControl" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

