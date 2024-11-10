import json
import os
import base64

import boto3

S3_BUCKET = os.environ['S3_BUCKET']
textract = boto3.client('textract', region_name='us-east-1')

def lambda_handler(event, context):
    s3 = boto3.client('s3')
    
    
    # Decode the PDF file data from base64
    file = base64.b64decode(event['body'])
    file_name = event['headers'].get('x-filename')
    # The directory to upload the file to
    source_directory = "uploads/"
    
    s3_key = f"{source_directory}{file_name}"
    
    full_text = ""
    try:
        # Quickly extracting one-page pdf files
        response = textract.detect_document_text(
        Document={'Bytes': file}
        )
        
        # Extract text lines from the response
        extracted_text = []
        for block in response['Blocks']:
            if block['BlockType'] == 'LINE':
                extracted_text.append(block['Text'])
        
        # Join text lines into a single string
        full_text = '\n'.join(extracted_text)
        
    except Exception as e:
        print("An error occured during textract before uploading the file to s3", e)
    try:
        # uploading to S3 bucket
        s3.put_object(
            Bucket=S3_BUCKET, 
            Key=s3_key, 
            Body=file, 
            ContentType='application/pdf'
        )
    except Exception as e:
        print('all the error ', e)
        print(e.response['Error']['Message'])
    print('The full text latest', full_text)
    return {
        "statusCode": 200,
        "headers": {
            'Access-Control-Allow-Methods': "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
            'Access-Control-Allow-Headers': "Content-Type,X-Filename,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
            'Access-Control-Allow-Origin': "*",
            "Content-Type": "application/json"
        },
        # "body": str({"response": full_text})
        "body": json.dumps({"text": full_text})
    }

