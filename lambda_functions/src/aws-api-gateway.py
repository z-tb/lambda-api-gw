#!/usr/bin/env python3
import json
import re
import html



def sanitize_name_input(data):
    """
    Sanitize input data by removing unwanted characters and escaping HTML content.
    Raises a ValueError if the input is not a string.
    """
    if not isinstance(data, str):
        raise ValueError("Input must be a string")
    
    # maximum length for a first or last name... 100?
    if len(data) > 100:
        raise ValueError("Input for name is too long")

    # Allow a-z, A-Z, 0-9, spaces, apostrophes (O'Malley), and hyphens (Jamieson-Jones)
    data = re.sub(r'[^a-zA-Z0-9\s\'-]', '', data)
    
    # escape HTML content
    data = html.escape(data)

    return data


def sanitize_zip_input(data):
    """
    Allow digits only for a max length of 10 and format as 12345-6789.
    Raises a ValueError if the input is not a string.
    """
    if not isinstance(data, str):
        raise ValueError("Input must be a string")

    # Allow only digits
    data = re.sub(r'[^0-9]', '', data)
    
    #  maximum length of 10 for zip code plus hyphen suffix thing
    if len(data) > 10:
        raise ValueError("Input for zip code is too long")
        
    # format as 12345-6789
    if len(data) == 10:
        data = f"{data[:5]}-{data[5:]}"

    return data



def sanitize_city_state_input(data):
    """
    Allow alphabetic characters and spaces, with a maximum length of 100.
    Raises a ValueError if the input is not a string.
    """
    if not isinstance(data, str):
        raise ValueError("Input must be a string")

    # Allow only alphabetic characters and spaces
    data = re.sub(r'[^a-zA-Z\s]', '', data)
    
    # check length max
    if len(data) > 100:
        raise ValueError("Input for city or state is too long")
    
    # maximum length of 100 becuase idk what the longest city is but a limit of 100 is better than unlimited
    data = data[:100]
    
    # escape HTML content
    data = html.escape(data)

    return data


def lambda_handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    
    try:
        # Parse the body of the POST request
        body = json.loads(event['body']) if event.get('body') else {}
        
             
        # Extract and sanitize form data
        first_name  = sanitize_name_input(body.get('firstName', '').strip())
        last_name   = sanitize_name_input(body.get('lastName', '').strip())
        city        = sanitize_city_state_input(body.get('city', '').strip())
        state       = sanitize_city_state_input(body.get('state', '').strip())
        zip_code    = sanitize_zip_input(body.get('zip', '').strip())
        
        
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