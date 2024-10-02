import boto3
import os

s3 = boto3.client('s3')
textract = boto3.client('textract')

def lambda_handler(event, context):
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        
        try:
            # Start Textract asynchronous processing, use env vars
            response = textract.start_document_text_detection(
                DocumentLocation={
                    'S3Object': {
                        'Bucket': bucket,
                        'Name': key
                    }
                }
            )
        except Exception as e:
            print(f"Error processing file {key} from bucket {bucket}: {str(e)}")
            
    return {
        'statusCode': 200,
        'body': 'Textract processing initiation is complete!'
    }