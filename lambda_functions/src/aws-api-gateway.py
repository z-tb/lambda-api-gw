#!/usr/bin/env python3
import json

def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse the body of the POST request
        body = json.loads(event['body']) if event.get('body') else {}
        
        # Extract form data
        first_name = body.get('firstName', '').strip()
        last_name = body.get('lastName', '').strip()
        city = body.get('city', '').strip()
        state = body.get('state', '').strip()
        zip_code = body.get('zip', '').strip()
        
        # Basic validation
        if not first_name or not last_name or not city or not state or not zip_code:
            raise ValueError("Missing required fields")
        
        # Process the data (you can add your own logic here)
        message = f"Hello, {first_name} {last_name} from {city}, {state} {zip_code}! Your form was submitted successfully."
        
        response = {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"message": message})
        }
    except ValueError as ve:
        print(f"Error processing request: {str(ve)}")
        response = {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(ve)})
        }
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        response = {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Internal Server Error"})
        }
    
    return response