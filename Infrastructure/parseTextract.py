import json
import boto3


textract = boto3.client('textract')
s3 = boto3.client('s3')

def lambda_handler(event, context):
    for record in event['Records']:
        try:
            # The SNS message wit job information
            sns_message = json.loads(record['Sns']['Message'])
            
            # Accessing the keys for getting Textract results
            job_id = sns_message['JobId']
            status = sns_message['Status']
            
            # Acessign the keys for destination
            bucket = sns_message['DocumentLocation']['S3Bucket']
            s3_object_key = sns_message['DocumentLocation']['S3ObjectName']
            file_name =  s3_object_key.split('/')[1].split('.')[0]
            
            if status == 'SUCCEEDED':
                # Proceed to get the document text detction results
                response = textract.get_document_text_detection(JobId=job_id)
                
                # Collect extracted text
                detected_text = []
                for item in response.get('Blocks', []):
                    if item['BlockType'] == 'LINE':
                        detected_text.append(item['Text'])
                
                # Save collected text to S3
                output_key = f"processed/{file_name}.txt"
                s3.put_object(
                    Bucket=bucket,
                    Key=output_key,
                    Body="\n".join(detected_text)
                )
            elif status == 'FAILED':
                print(f"Job {job_id} failed.")
            
        except KeyError as e:
            print(f"KeyError: Missing expecte key {str(e)}")
        
        except Exception as e:
            print(f"Error prcessing job")
        
    return {
        'statusCode': 200,
        'body': 'Notification processed succesfully!'
    }