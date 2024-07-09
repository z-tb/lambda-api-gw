#!/usr/bin/env python3
import boto3
import json

def lambda_handler(event, context):
  print (f"Received event: {event}")
  
  statusCode = 200
  returnBody = {"message": "Hello from Lambda"}

  # Return a response
  response = {
      "statusCode": statusCode,
      "headers": {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"  # For CORS support
      },
      "body": json.dumps(returnBody)
  }
    
  return response

