
# Define the Lambda IAM role
resource "aws_iam_role" "lambda_role" {
  name = "${var.name_tag}-LAM-ROLE"

  # Allow Lambda to use AssumeRole
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

  # Attach a policy that allows writing to CloudWatch Logs
  # note: Terraform docs open this up a lot
  # https://registry.terraform.io/providers/hashicorp/aws/3.56.0/docs/resources/lambda_function
  inline_policy {
    name = "${var.name_tag}-CW-POL"

    policy = jsonencode({
      Version   = "2012-10-17",
      Statement = [
        {
          Action   = ["logs:CreateLogGroup", 
                      "logs:CreateLogStream",
                      "logs:PutLogEvents"],
          Effect   = "Allow",
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }


  # Allow access to the specified Secrets Manager secret
  # follow Resource with "*" because the ARN for the secret has a few AWS generated characters after the actual name
  /*
  inline_policy {
    name = "${var.name_tag}-SM-POL"

  
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
  }*/

  # Allow access to SSM Parameter Store with a specific prefix
  /*
  inline_policy {
    name = "${var.name_tag}-SSM-POL"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeParameters"
            ],
            "Resource": "*"
        },
        {
          Action   = ["ssm:GetParameter", "ssm:GetParameters", "ssm:GetParametersByPath"],
          Effect   = "Allow",
          Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/*",
        },
      ]
    })
  }*/
  

  # Cost Usage/Explorer
  /*
  # Resource needs to be "*" here as that is all that is allowed in the policy editor
  inline_policy {
    name = "${var.name_tag}-CE-POL"

    policy = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Action   = ["ce:GetCostAndUsage", "ce:GetCostForecast"],
          Effect   = "Allow",
          Resource = "*",
        },
      ]
    })
  }*/
    

  tags = {
    Name        = var.name_tag
    Owner       = var.owner_tag
    Environment = var.environment_tag
  }
}

