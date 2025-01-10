# AWS Lambda and API Gateway Project

## Overview
This project sets up an AWS Lambda function and an API Gateway to handle HTTP requests. The Lambda function processes form data submitted via the API Gateway and returns a response. The project includes Terraform configurations to provision the necessary AWS resources and the Lambda function code to handle the form data.

## Features
- **Terraform Configuration**:
  - Provisions an AWS Lambda function.
  - Sets up an API Gateway with a POST method to invoke the Lambda function.
  - Configures IAM roles and policies for the Lambda function.
  - Creates a CloudWatch Log Group for logging Lambda function output.
  - Ensures secure and sanitized input handling.

- **Lambda Function**:
  - Processes form data submitted via the API Gateway.
  - Sanitizes input data to prevent injection attacks and other malicious input.
  - Validates input data to ensure it meets the required format and length.
  - Returns a success message if the input data is valid.
  - Returns an error message if the input data is invalid or missing required fields.

## Prerequisites
- AWS Account
- Terraform installed
- AWS CLI configured with appropriate permissions

## Getting Started
1. **Clone the Repository**:
   ```sh
   git clone <repository-url>
   cd <repository-directory>
   ```

2. **Initialize Terraform**:
   ```sh
   terraform init
   ```

3. **Apply Terraform Configuration**:
   ```sh
   terraform apply
   ```

4. **Test the API**:
   Use `curl` or any API testing tool to send a POST request to the API Gateway endpoint with the required form data.
   ```sh
   curl -X POST "https://<api-gateway-id>.execute-api.<region>.amazonaws.com/test/example" \
        -H "x-api-key: <your-api-key>" \
        -H "Content-Type: application/json" \
        -d '{
              "firstName": "John",
              "lastName": "Doe",
              "city": "San Francisco",
              "state": "CA",
              "zip": "94103"
            }'
   ```

## Security Considerations
- The Lambda function sanitizes and validates input data to prevent injection attacks and other malicious input.
- The API Gateway is secured with API keys to control access.
- IAM roles and policies are configured to grant the Lambda function the necessary permissions while following the principle of least privilege.

## Contributing
Feel free to contribute to this project by submitting issues and pull requests.

## License
This project is licensed under the MIT License. See the LICENSE file for more information.


* the lambda src and layers directory structure. Install python libraries
* python modules would be installed via: cd lambda_functions && pip install -r requirements.txt --target layers/
```bash
lambda_functions/
├── requirements.txt
├── my_lambda_function.zip
├── my_lambda_layer.zip
├── layers
│   └── python
│       └── some_sdk
└── src
    └── aws-api-gateway.py
```
