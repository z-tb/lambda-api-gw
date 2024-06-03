variable "aws_region" {
  description = "The AWS region where the S3 bucket will be created."
  type        = string
  default     = "us-east-2" # You can change the default to your preferred region
}

variable "name_tag" {
  description = "The 'Name' tag for the S3 bucket."
  type        = string
  default     = "default-name-tag"
}

variable "owner_tag" {
  description = "The 'Owner' tag for the S3 bucket."
  type        = string
  default     = "default-owner-tag"
}

variable "environment_tag" {
  description = "The 'Environment' tag for the S3 bucket."
  type        = string
  default     = "default-env-tag"
}

#-------------  Lambda variables --------------#

# Define variables for Lambda function source directory and output path
variable "lambda_script_filename" {
  description = "Name of the Python Lambda script file."
  type        = string
  default     = "my_lambda_function.py"  # Replace with the actual filename
}

variable "lambda_source_dir" {
  description = "Path to the source directory of the Lambda function."
  type        = string
  default     = "lambda_functions/src" # Default source directory path
}

# where to place the output zip file
variable "lambda_output_path" {
  description = "Path to the output ZIP file for the Lambda function."
  type        = string
  default     = "lambda_functions/my_lambda_function.zip" # Default output ZIP file path
}

variable "lambda_function_runtime" {
  description = "Lambda function runtime."
  type        = string
  default     = "python3.8" # Default runtime
}

variable "lambda_run_timeout" {
  description = "Lambda function allowed runtime in seconds"
  type        = string
}

variable "lambda_log_retention_duration" {
  description = "Duration in days for CloudWatch log retention of Lambda logs"
  type        = number
  default     = 30  # Default retention policy 
}

# lambda layer additions
variable "lambda_layer_source_dir" {
  description = "Path to the Lambda Layer source directory"
  type        = string
}

variable "lambda_layer_output_path" {
  description = "Output path for the Lambda Layer ZIP archive"
  type        = string
}

variable "lambda_handler" {
  description = "Name of the function for AWS to invoke in the lambda"
  type        = string
}


