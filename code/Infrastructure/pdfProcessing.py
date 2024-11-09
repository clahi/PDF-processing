import boto3
import time
import os

s3 = boto3.client('s3')
textract = boto3.client('textract', region_name='us-east-1')

def lambda_handler(event, context):
    
    topic_arn = os.environ['TEXTRACT_NOTIFICATION_TOPIC']
    textract_role = os.environ['TEXTRACT_ROLE_ARN']
    
    for record in event['Records']:
        bucket = record['s3']['bucket']['name']
        key = record['s3']['object']['key']
        print('The key', key)
        print('bucket Name', bucket)
        
        try:
            # time.sleep(2)
            # Start Textract asynchronous processing, use env vars
            response = textract.start_document_text_detection(
                DocumentLocation={
                    'S3Object': {
                        'Bucket': bucket,
                        'Name': key
                    }
                },
                NotificationChannel={
                    "RoleArn": textract_role,
                    "SNSTopicArn": topic_arn,
                },
            )
            print('Entered Here after processing', response)
        except Exception as e:
            print(f"Error processing file {key} from bucket {bucket}: {str(e)}")
            
    return {
        'statusCode': 200,
        'body': 'Textract processing initiation is complete!'
    }