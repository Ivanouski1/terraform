provider "aws" {
  shared_credentials_files = ["creds/credentials"]
  shared_config_files      = ["creds/config"]
}


# ---------------create key-pair from pre-created keys-------------
resource "aws_key_pair" "aws-key" {
  key_name   = "aws-key"
  public_key = data.local_file.public_key.content
}

# ---------------create S3 backet---------------
resource "aws_s3_bucket" "my_web" {
  bucket        = var.bucket_name
  acl           = "private"
  force_destroy = true

    }
  



resource "aws_s3_bucket_public_access_block" "s3block" {
  bucket                  = aws_s3_bucket.my_web.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

#----------------create folder------------------https://www.youtube.com/watch?v=3ahcgi8RqCM

resource "aws_s3_bucket_object" "my_folder_A" {
  bucket       = aws_s3_bucket.my_web.id
  acl          = "private"
  key          = "${var.new_folder_A}/"
  content_type = "application/x-directory"
}

resource "aws_s3_bucket_object" "my_folder_B" {
  bucket       = aws_s3_bucket.my_web.id
  acl          = "private"
  key          = "${var.new_folder_B}/"
  content_type = "application/x-directory"
}
# ------------upload files----------
resource "aws_s3_bucket_object" "inside_folder_A" {
  bucket   = aws_s3_bucket.my_web.id
  for_each = fileset("${var.path_to_work_directory}/A/", "*")
  key      = "${var.new_folder_A}/${each.value}"
  source   = "${var.path_to_work_directory}/A/${each.value}"
  etag     = filemd5("${var.path_to_work_directory}/A/${each.value}")
  content_type = "text/html"
}
resource "aws_s3_bucket_object" "inside_folder_B" {
  bucket       = aws_s3_bucket.my_web.id
  for_each     = fileset("${var.path_to_work_directory}/B/", "*")
  key          = "${var.new_folder_B}/${each.value}"
  source       = "${var.path_to_work_directory}/B/${each.value}"
  etag         = filemd5("${var.path_to_work_directory}/B/${each.value}")
  content_type = "text/html"
}
resource "aws_s3_bucket_object" "front_html" {
  bucket       = aws_s3_bucket.my_web.id
  key          = "front.html"
  source       = "${var.path_to_work_directory}/front.html"
  etag         = filemd5("${var.path_to_work_directory}/front.html")
  content_type = "text/html"
}
resource "aws_s3_bucket_object" "app_js" {
  bucket = aws_s3_bucket.my_web.id
  key    = "app.js"
  source = "${var.path_to_work_directory}/app.js"
  etag   = filemd5("${var.path_to_work_directory}/app.js")
  #content_type = "text/js"
}

#----------Origin Access Identity--------
resource "aws_cloudfront_origin_access_identity" "my-app-read" {
  comment = "my-app-read"
}
# ----------------Main cloudfront distribution with S3 origin------------------https://www.youtube.com/watch?v=S-rZl9VYgnU

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.my_web.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.my_web.bucket_regional_domain_name
    origin_path = "/A/*"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.my-app-read.cloudfront_access_identity_path
    }
  }

  enabled = true


  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.my_web.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = []

      cookies {
        forward = "all"
      }
    }
  }

  ordered_cache_behavior {
    path_pattern           = "/*"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_s3_bucket.my_web.bucket_regional_domain_name
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = []

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


#--------------Create policy and binding to OAI
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.my_web.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.my-app-read.iam_arn]
    }
  }
  depends_on = [
    aws_cloudfront_distribution.s3_distribution
  ]
}


resource "aws_s3_bucket_policy" "s3_policy" {
  bucket = aws_s3_bucket.my_web.id
  policy = data.aws_iam_policy_document.s3_policy.json

}

#------------Deploy Lambda-function-----------https://www.youtube.com/watch?v=Lkm3v7UDlD8

resource "aws_lambda_function" "my-api" {
  count         = "2"
  filename      = "scripts/api${count.index + 1}.zip" # see in data.tf
  function_name = "my-api-${count.index + 1}"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "api${count.index + 1}.lambda_handler" # names file and function
  runtime       = "python3.9"

  ephemeral_storage {
    size = 10240 # Min 512 MB and the Max 10240 MB
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "clw" {
  name = "clw"
  role = aws_iam_role.iam_for_lambda.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": [
                "arn:aws:logs:us-east-1:*:*"
            ]
        }
    ]
}
EOF
}

resource "aws_lambda_permission" "allow-api-lambda" {
  count         = "2"
  statement_id  = "AllowAPIgatewayInvokation"
  action        = "lambda:InvokeFunction"
  function_name = element(aws_lambda_function.my-api.*.function_name, count.index)
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.my-api.execution_arn}/*/*"
}


#---------------API-------------------------------
resource "aws_api_gateway_rest_api" "my-api" {
  name        = "my-api"
  description = "rest api, created by alparius/api-gateway-with-cors"
}
### api route
resource "aws_api_gateway_resource" "rout_lambda" {
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  parent_id   = aws_api_gateway_rest_api.my-api.root_resource_id
  count       = "2"
  path_part   = "my-api-${count.index + 1}"
}

### connecting the api gateway with the internet
resource "aws_api_gateway_method" "main_method" {
  count         = "2"
  rest_api_id   = aws_api_gateway_rest_api.my-api.id
  resource_id   = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method   = var.http_method
  authorization = "NONE"

  request_parameters = var.request_parameters
}

### default 'OK' response
resource "aws_api_gateway_method_response" "main_method_200" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.main_method.*.http_method, count.index)
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

### connecting the api gateway with the lambda
resource "aws_api_gateway_integration" "method_integration" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  #resource_id = "${element(aws_api_gateway_method.main_method.*.resource_id, count.index)}"
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.main_method.*.http_method, count.index)

  integration_http_method = "POST"
  type                    = "AWS"
  #uri                     = "${"aws_lambda_function.my-api-${count.index +1}.invoke_arn"}"
  uri = element(aws_lambda_function.my-api.*.invoke_arn, count.index)


  request_templates = var.request_templates

  depends_on = [aws_api_gateway_method.main_method]
}

### integration response
resource "aws_api_gateway_integration_response" "method_integration_200" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.main_method.*.http_method, count.index)
  status_code = element(aws_api_gateway_method_response.main_method_200.*.status_code, count.index)


  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_method_response.main_method_200,
    aws_api_gateway_integration.method_integration
  ]
}


resource "aws_api_gateway_method" "options_method" {
  count         = "2"
  rest_api_id   = aws_api_gateway_rest_api.my-api.id
  resource_id   = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_response" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.options_method.*.http_method, count.index)
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration" "options_integration" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.options_method.*.http_method, count.index)
  type        = "MOCK"

  request_templates = {
    "application/json" = "{ \"statusCode\": 200 }"
  }

  depends_on = [aws_api_gateway_method.options_method]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  count       = "2"
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  resource_id = element(aws_api_gateway_resource.rout_lambda.*.id, count.index)
  http_method = element(aws_api_gateway_method.options_method.*.http_method, count.index)
  status_code = element(aws_api_gateway_method_response.options_response.*.status_code, count.index)

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method_response.options_response,
    aws_api_gateway_integration.options_integration
  ]
}

# at last, deployment
# ------------------------------------------------------------------

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.my-api.id
  stage_name  = var.stage_name

  depends_on = [
    aws_api_gateway_integration.method_integration,
    aws_api_gateway_integration.options_integration
  ]
}