output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

output "api_domain_id" {
  description = "replace hands in file app.js"
  value       = aws_api_gateway_rest_api.my-api.id
}
