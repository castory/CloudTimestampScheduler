terraform {
    backend "s3" {
      bucket = "kaigos"
      key    = "key/terraform.tfstate"
      region = "us-east-1"
    }
}

provider "aws" {
 
#profile     = "shared-credentials-file"

  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

}

# S3 Bucket
resource "aws_s3_bucket" "kaios02-mg" {
  bucket = "kaigos02-mg"
  
}

# KMS Key
resource "aws_kms_key" "my_kms_key" {
  description             = "kaigos-kms01"
  deletion_window_in_days = 7
}

resource "aws_s3_bucket_server_side_encryption_configuration" "myencryption" {
  bucket = aws_s3_bucket.kaios02-mg.bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.my_kms_key.arn
      sse_algorithm = "aws:kms"
    }
  }
}


# Lambda function

resource "aws_iam_role" "s3_put_policy_role" {
  name = "S3PutPolicy"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "s3_put_policy_attachment" {
  name       = "S3PutPolicyAttachment"
  policy_arn = aws_iam_policy.s3_put_policy.arn
  roles      = [aws_iam_role.lambda_execution_role.name]
  depends_on = [aws_iam_role_policy_attachment.lambda_execution_policy_attachment]
}

resource "aws_iam_policy" "s3_put_policy" {
  name        = "S3PutPolicy"
  description = "IAM policy for Lambda with S3 Put and Get permissions and KMS test permissions"
  
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject"
      ],
      "Resource": [
        "arn:aws:s3:::kaigos02-mg/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:GenerateDataKey"
      ],
      "Resource": [
        aws_kms_key.my_kms_key.arn
      ]
    }
  ]
}
EOF
}


resource "aws_lambda_function" "example_lambda" {
  function_name = "example_lambda_function"
  runtime       = "python3.8"
  handler       = "lambda_function.lambda_handler"
  timeout       = 60
  memory_size   = 128

  role = aws_iam_role.lambda_execution_role.arn

  #source_code_hash = filebase64("lambda_function.zip")
  filename         = "example_lambda_function.zip"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.kaios02-mg.bucket
      KMS_KEY_ARN = KMS_KEY_ARN = var.kms_key_arn
    }
  }
  depends_on = [
    aws_iam_policy_attachment.s3_put_policy_attachment,
    aws_iam_policy_attachment.lambda_execution_policy_attachment,
  ]
  
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com",
      },
    }],
  })
}

resource "aws_iam_role_policy_attachment" "lambda_execution_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_execution_role.name
}

resource "aws_cloudwatch_event_rule" "example_schedule" {
  name        = "example_schedule"
  description = "Trigger Lambda every 10 minutes"

  schedule_expression = "cron(0/10 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.example_schedule.name
  target_id = "example_lambda_target"
  arn       = aws_lambda_function.example_lambda.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name = "/aws/lambda/${aws_lambda_function.example_lambda.function_name}"
}

resource "aws_cloudwatch_metric_alarm" "lambda_error_alarm" {
  alarm_name          = "lambda_error_alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  dimensions = {
    FunctionName = aws_lambda_function.example_lambda.function_name
  }

  alarm_description = "Alarm when Lambda function errors occur"
}

# API Gateway
resource "aws_api_gateway_rest_api" "example_api" {
  name        = "example_api"
  description = "Example API"
}

resource "aws_api_gateway_resource" "example_resource" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  parent_id   = aws_api_gateway_rest_api.example_api.root_resource_id
  path_part   = "timestamp"
}

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.example_api.id
  resource_id   = aws_api_gateway_resource.example_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "example_integration" {
  rest_api_id             = aws_api_gateway_rest_api.example_api.id
  resource_id             = aws_api_gateway_resource.example_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.example_lambda.invoke_arn
}

resource "aws_api_gateway_method_response" "example_method_response" {
  rest_api_id = aws_api_gateway_rest_api.example_api.id
  resource_id = aws_api_gateway_resource.example_resource.id
  http_method = aws_api_gateway_method.example_method.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Content-Type" = true
  }
}

resource "aws_api_gateway_deployment" "example_deployment" {
  depends_on = [aws_api_gateway_integration.example_integration]

  rest_api_id = aws_api_gateway_rest_api.example_api.id
  stage_name  = "prod"
}

output "api_gateway_url" {
  value = aws_api_gateway_deployment.example_deployment.invoke_url
}
