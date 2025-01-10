/* to test the api gateway, generate an API key and:

$ curl -X POST "https://4pb1r7y0l9.execute-api.us-west-2.amazonaws.com/test/example" \
     -H "x-api-key: KI...4NX" \
     -H "Content-Type: application/json" \
     -d '{
           "firstName": "John",
           "lastName": "Doe",
           "city": "San Francisco",
           "state": "CA",
           "zip": "94103"
         }'
{"message": "Hello, John Doe from San Francisco, CA 94103! Your form was submitted successfully."}


*/

# account id for the lambda role policy
data "aws_caller_identity" "current" {}

locals {
  lambda_script_filename  = "${var.name_tag}.py"
  lambda_arn              = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.name_tag}"
  lambda_name             = var.name_tag
  cw_log_group_name       = "/aws/lambda/${local.lambda_name}"
}

# Create a ZIP archive of the Lambda function
data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = var.lambda_output_path
}

# Monitor the source lambda function for changes and re-zip the file if changed
resource "null_resource" "generate_lambda_zip" {
  triggers = {
    source_file_hash = filebase64sha256("${var.lambda_source_dir}/${local.lambda_script_filename}")
  }

  provisioner "local-exec" {
    command = "cd ${var.lambda_source_dir} && zip -r ../../${var.lambda_output_path} ${local.lambda_script_filename}"
  }
}

# Define the Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  description       = "Runs periodically via CloudWatch to monitor costs. Sends alerts via Slack. Configurable threshold is in ParameterStore"
  filename          = data.archive_file.lambda_function_zip.output_path
  function_name     = local.lambda_name
  role              = aws_iam_role.lambda_role.arn
  handler           = "${local.lambda_name}.${var.lambda_handler}"
  source_code_hash  = data.archive_file.lambda_function_zip.output_base64sha256
  runtime           = var.lambda_function_runtime
  timeout           = var.lambda_run_timeout

  depends_on = [
    aws_iam_role.lambda_role,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

# Define the CloudWatch Log Group with retention policy
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.cw_log_group_name
  retention_in_days = var.lambda_log_retention_duration

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

# Define the API Gateway
resource "aws_api_gateway_rest_api" "my_api_gw" {
  name        = "${local.lambda_name}-API-GATEWAY"
  description = "API gateway for lambda function ${local.lambda_name}"

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

resource "aws_api_gateway_resource" "my_gw_resource" {
  rest_api_id = aws_api_gateway_rest_api.my_api_gw.id
  parent_id   = aws_api_gateway_rest_api.my_api_gw.root_resource_id
  path_part   = "example"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api_gw.id
  resource_id   = aws_api_gateway_resource.my_gw_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api_gw.id
  resource_id   = aws_api_gateway_resource.my_gw_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "my_gw_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api_gw.id
  resource_id             = aws_api_gateway_resource.my_gw_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_api_gateway_integration" "my_gw_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.my_api_gw.id
  resource_id             = aws_api_gateway_resource.my_gw_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.my_api_gw.execution_arn}/*/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "my_api_gw_deployment" {
  depends_on = [
    aws_api_gateway_integration.my_gw_integration,
    aws_api_gateway_integration.my_gw_integration_post,
    aws_api_gateway_method.get_method,
    aws_api_gateway_method.post_method
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api_gw.id
  description = "Deployed at ${timestamp()}"

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_integration.my_gw_integration,
      aws_api_gateway_integration.my_gw_integration_post,
      aws_api_gateway_method.get_method,
      aws_api_gateway_method.post_method
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "my_stage" {
  deployment_id = aws_api_gateway_deployment.my_api_gw_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.my_api_gw.id
  stage_name    = "test"

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

# Output the URL of the deployed API Gateway
output "api_gateway_url" {
  value = "${aws_api_gateway_stage.my_stage.invoke_url}/${aws_api_gateway_resource.my_gw_resource.path_part}"
}
