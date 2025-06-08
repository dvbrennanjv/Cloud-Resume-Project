terraform {
  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_s3_bucket" "resume_bucket" {
  bucket = var.resume_bucket_name

  tags = {
    Name = "resume-bucket"
  }
}

resource "aws_s3_bucket_policy" "resume_bucket_policy" {
  bucket = aws_s3_bucket.resume_bucket.id
  policy = file("${path.module}/bucket-policy.txt")
}

resource "aws_cloudfront_origin_access_control" "resume_oac" {
  name                             = "resume-oac"
  description                      = "OAC for CloudFront distribution"
  origin_access_control_origin_type = "s3"
  signing_behavior                 = "always"
  signing_protocol                 = "sigv4"
}

resource "aws_cloudfront_distribution" "resume_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_100"
  default_root_object = "index.html"
  http_version        = "http3"
  aliases             = [var.resume_domain_name]

  origin {
    origin_id                = aws_s3_bucket.resume_bucket.id
    domain_name              = aws_s3_bucket.resume_bucket.bucket_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.resume_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.resume_bucket.id
    default_ttl            = 3600
    min_ttl                = 0
    max_ttl                = 86400

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.domain_cert_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "aws_dynamodb_table" "view_counter_db" {
    name = "view-counter"
    billing_mode = "PAY_PER_REQUEST"

    hash_key = "id"

    attribute {
      name = "id"
      type = "S"
    }
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-dynamodb-execution-role"
  assume_role_policy = file("${path.module}/execution-policy.txt")
}

resource "aws_iam_policy" "lambda_dynamodb_policy" {
  name = "lambda-dynamodb-policy"
  policy = file("${path.module}/lambda-policy.txt")
}

resource "aws_iam_role_policy_attachment" "name" {
  depends_on = [ aws_iam_policy.lambda_dynamodb_policy, aws_iam_role.lambda_execution_role ]
  role = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb_policy.arn
}

resource "aws_lambda_function" "view_counter_function" {
  function_name = "viewer-counter"
  runtime = "python3.13"
  handler = "view_counter.lambda_handler"
  filename = "view_counter.zip"
  role = aws_iam_role.lambda_execution_role.arn

  source_code_hash = filebase64sha256("view_counter.zip")

}

resource "aws_apigatewayv2_api" "view_counter_api" {
  name = "view-counter-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers = ["*"]
    allow_methods = ["GET"]
    allow_origins = ["https://${var.resume_domain_name}"]
    expose_headers = []
    max_age = 3600
  }
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id = aws_apigatewayv2_api.view_counter_api.id
  integration_type = "AWS_PROXY"
  integration_uri = aws_lambda_function.view_counter_function.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "view_counter_route" {
  api_id = aws_apigatewayv2_api.view_counter_api.id
  route_key = "GET /views"
  target = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "prod_stage" {
  api_id = aws_apigatewayv2_api.view_counter_api.id
  name = "prod"
}

resource "aws_lambda_permission" "allow_api" {
  statement_id = "AllowExecutionFromAPIGateway"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.view_counter_function.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "${aws_apigatewayv2_api.view_counter_api.execution_arn}/*/*"
}