
def lambda_handler(event, context):
  print (f"Received event: {event}")
  
  statusCode = 200
  returnBody = "Hello from Lambda"

  # Return a response
  response = {
        "statusCode": statusCode,
        "body": returnBody
    }
      
  return response

