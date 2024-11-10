output "s3_url_name" {
  description = "The url name assocaited with the static web page hosted on s3"
  value = aws_s3_bucket.my-static-website.website_endpoint
}

output "cloudFront_domain_name" {
  description = "The domain name of the cloudFront distributing the s3 static web page"
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}