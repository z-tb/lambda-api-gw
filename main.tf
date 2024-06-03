# 
# terraform init -var-file="test-env.tfvars"

# account id for the lambda role policy
data "aws_caller_identity" "current" {}

locals {
  lambda_script_filename  = "${var.name_tag}.py"
  #arn:aws:secretsmanager:us-east-1:123456789012:secret:your-secret-name-AbCdEf
  #slack_secret_arn        = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.sm_slack_token}"
  lambda_arn              = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:${var.name_tag}"
  
  # cloudwatch log group needed in various places
  # only works correctly if named the same as the lambda_function name. This matters for setting retention.
  lambda_name             = var.name_tag
  cw_log_group_name       = "/aws/lambda/${local.lambda_name}"  
}

# Create a ZIP archive of the Lambda function
data "archive_file" "lambda_function_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = var.lambda_output_path
}


# the lambda layer zip file
/*
data "archive_file" "lambda_layer_zip" {
  type        = "zip"
  source_dir  = var.lambda_layer_source_dir
  output_path = var.lambda_layer_output_path
}*/


# monitor the source lambda function for changes and re-zip the file if changed
resource "null_resource" "generate_lambda_zip" {
  triggers = {
    source_file_hash = filebase64sha256("${var.lambda_source_dir}/${local.lambda_script_filename}") #<-- monitor the source python script for changes
  }

  provisioner "local-exec" {
    #command = "zip -r ${var.lambda_output_path} ${var.lambda_source_dir}"
    command = "cd ${var.lambda_source_dir} && zip -r ../../${var.lambda_output_path} ${local.lambda_script_filename}"
  }
}


# run some shell code to create a JSON-ized checksum of all files in they layers/ directory 
data "external" "lambda_layer_zip" {
  program = ["sh", "-c", "cat $(find ${var.lambda_layer_source_dir} -type f | sort) | sha1sum | base64 | { read hash; printf '{\"result\": \"%s\"}' \"$hash\"; }"]
}

# monitor changes in the lambda layer directory source and re-zip if changed
# no script to monitor as these are libraries added with: pip install <library-name> -t ./layers
# eg: pip3 install slack_sdk -t ./lambda_functions/layers/
/*
resource "null_resource" "generate_lambda_layer_zip" {
  triggers = {
    # use the JSON-iszed checksum to determine if the zip needs to be re-created
    source_files_hash = data.external.lambda_layer_zip.result["result"]
  }

  provisioner "local-exec" {
    command = "cd ${var.lambda_layer_source_dir} && zip -r ../../${var.lambda_layer_output_path} ."
  }
}
*/


# Define the Lambda function
resource "aws_lambda_function" "my_lambda_function" {
  # Use the ZIP file created by the archive_file data source
  description       = "Runs periodically via CloudWatch to monitor costs. Sends alerts via Slack. Configurable threshold is in ParameterStore"
  filename          = data.archive_file.lambda_function_zip.output_path
  function_name     = local.lambda_name
  role              = aws_iam_role.lambda_role.arn
  handler           = "${local.lambda_name}.${var.lambda_handler}"
  source_code_hash  = data.archive_file.lambda_function_zip.output_base64sha256  #<-- monitor the source python script for changes
  runtime           = var.lambda_function_runtime
  # allow this to run longer than the default 3 seconds 
  timeout           = var.lambda_run_timeout
  # include layers for the lambda to use
  # layers            = [aws_lambda_layer_version.my_lambda_layer.arn]
  
  # Make sure the log group (and IAM role?) has been created first, or you'll get two -- one you want, and the other is a default
  depends_on = [
    aws_iam_role.lambda_role,
    aws_cloudwatch_log_group.lambda_logs
  ]

   # supply the name of the parameter store/secrets manager keys to the lambda function
   /*
  environment {
    variables = {
      DAYS_TO_AVERAGE_KEY = "${var.pstore_prefix}/${var.pstore_days_to_average_key }"
      COST_THRESHOLD_KEY  = "${var.pstore_prefix}/${var.pstore_daily_cost_threshold_key}"
      SM_SLACK_TOKEN      = "${var.sm_slack_token}"
      SLACK_CHANNEL       = "${var.slack_channel}"
      DAY_TO_POST_STATUS  = "${var.pstore_prefix}/${var.pstore_status_update_day_key}"
      HOUR_TO_POST_STATUS = "${var.pstore_prefix}/${var.pstore_status_update_hour_key}"
    }
  }*/

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }  
}


# define the lambda layer version resource
# no tags
/*
resource "aws_lambda_layer_version" "my_lambda_layer" {
  layer_name          = "${var.name_tag}-LAM-LAYER"
  description         = "A lambda layer for ${var.name_tag}"
  compatible_runtimes = ["python3.8"]  # Specify the compatible runtime for your layer
  source_code_hash    = data.archive_file.lambda_layer_zip.output_base64sha256
  filename            = data.archive_file.lambda_layer_zip.output_path  
}
*/

# Define the CloudWatch Log Group with retention policy to something reasonable to manage storage costs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = local.cw_log_group_name
  retention_in_days = var.lambda_log_retention_duration  # Set retention policy to 7 days

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

# = = = = = = = = = = = = =  = = = = = = = = = = = = =  = = = = = = = = = = = = =  = = = = = = = = = = = = = 
# rest API
# = = = = = = = = = = = = =  = = = = = = = = = = = = =  = = = = = = = = = = = = =  = = = = = = = = = = = = = 

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

resource "aws_api_gateway_method" "example_method" {
  rest_api_id   = aws_api_gateway_rest_api.my_api_gw.id
  resource_id   = aws_api_gateway_resource.my_gw_resource.id
  http_method   = "GET"

  # allow anyone to call the api endpoint
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "my_gw_integration" {
  rest_api_id             = aws_api_gateway_rest_api.my_api_gw.id
  resource_id             = aws_api_gateway_resource.my_gw_resource.id
  http_method             = aws_api_gateway_method.example_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.my_lambda_function.invoke_arn
  
  
}

resource "aws_lambda_permission" "my_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  # This depends on the API Gateway stage created by the integration, replace "example" with your actual stage name
  source_arn = "${aws_api_gateway_rest_api.my_api_gw.execution_arn}/example/*/*"
}

resource "aws_lambda_permission" "api_gateway_invoke_permission" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.my_lambda_function.arn
  principal     = "apigateway.amazonaws.com"

  #  API Gateway resource arn
  source_arn = "arn:aws:execute-api:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.my_api_gw.id}/*/*/*"
}

# Define the API Gateway deployment
resource "aws_api_gateway_deployment" "my_api_gw_deployment" {
  depends_on = [
    aws_api_gateway_integration.my_gw_integration,
    aws_api_gateway_method.example_method
  ]
  rest_api_id = aws_api_gateway_rest_api.my_api_gw.id
  stage_name  = "test"
}

# Output the URL of the deployed API Gateway
output "api_gateway_url" {
  value = aws_api_gateway_deployment.my_api_gw_deployment.invoke_url
}