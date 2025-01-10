# Define the Lambda IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_tag}-LAM-ROLE"
  
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}


# CloudWatch Logs policy
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name        = "${var.name_tag}-CW-POL"
  description = "IAM policy for CloudWatch Logs"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = [
          "logs:CreateLogGroup", 
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = [
          "${aws_cloudwatch_log_group.lambda_logs.arn}",
          "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
        ]
      }
    ]
  })
}


# Attach CloudWatch policy to role
resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_policy.arn
}


# Secrets Manager policy (commented out but updated format)
/*
resource "aws_iam_policy" "lambda_secretsmanager_policy" {
  name        = "${var.name_tag}-SM-POL"
  description = "IAM policy for Secrets Manager access"

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Action   = "secretsmanager:GetSecretValue",
        Effect   = "Allow",
        Resource = "${local.slack_secret_arn}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secretsmanager" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_secretsmanager_policy.arn
}
*/

# SSM Parameter Store policy (commented out but updated format)
/*
resource "aws_iam_policy" "lambda_ssm_policy" {
  name        = "${var.name_tag}-SSM-POL"
  description = "IAM policy for SSM Parameter Store access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Action    = ["ssm:DescribeParameters"],
        Resource  = "*"
      },
      {
        Action    = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Effect    = "Allow",
        Resource  = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ssm" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ssm_policy.arn
}
*/

# Cost Explorer policy (commented out but updated format)
/*
resource "aws_iam_policy" "lambda_ce_policy" {
  name        = "${var.name_tag}-CE-POL"
  description = "IAM policy for Cost Explorer access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = [
          "ce:GetCostAndUsage",
          "ce:GetCostForecast"
        ],
        Effect    = "Allow",
        Resource  = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_ce" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ce_policy.arn
}
*/