resource "aws_s3_bucket" "my_bucket" {
  bucket = "my-bucket-serverless-source-01"
}

resource "aws_s3_bucket_ownership_controls" "bucketOwnershipControl" {
  bucket = aws_s3_bucket.my_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "accessBlock" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

}

resource "aws_s3_bucket_acl" "bucketAcl" {
  bucket = aws_s3_bucket.my_bucket.id
  acl    = "public-read"
  depends_on = [
    aws_s3_bucket_ownership_controls.bucketOwnershipControl,
    aws_s3_bucket_public_access_block.accessBlock
  ]
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "PublicReadGetObject",
        "Effect" : "Allow",
        "Principal" : "*",
        "Action" : [
          "s3:*"
        ],
        "Resource" : [
          "arn:aws:s3:::my-bucket-serverless-source-01/*"
        ]
      }
    ]
  })
  depends_on = [
    aws_s3_bucket_ownership_controls.bucketOwnershipControl,
    aws_s3_bucket_public_access_block.accessBlock
  ]
}

