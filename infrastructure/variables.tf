variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = "us-west-1"
}

variable "resume_bucket_name" {
  description = "S3 bucket name to host the resume site"
  type        = string
}

variable "resume_domain_name" {
  description = "Domain name (e.g. example.com) used for CloudFront alias"
  type        = string
}

variable "domain_cert_arn" {
  description = "ACM certificate ARN for the custom domain"
  type        = string
}
