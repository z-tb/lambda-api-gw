aws_region      = "us-west-2"
name_tag        = "aws-api-gateway"
owner_tag       = "tmb"
environment_tag = "test"

# lambda variables
lambda_source_dir               = "lambda_functions/src"
lambda_output_path              = "lambda_functions/my_lambda_function.zip" 
lambda_function_runtime         = "python3.9"
lambda_handler                  = "lambda_handler"
lambda_log_retention_duration   = 30  # how many days to retain lambda logs
lambda_run_timeout              = 300

# lambda layer variables
lambda_layer_source_dir         = "lambda_functions/layers"
lambda_layer_output_path        = "lambda_functions/my_lambda_layer.zip"


