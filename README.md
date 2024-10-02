# PDF-processing
Serverless PDF Processing with AWS Lambda and Textract.

# Overview
AWS Textract is a powerful service that automates the extraction of text and data from documents like PDFs.
It's a serverless, fully managed by amazon and it's far more cost-effective than training or using an AI model.

When combined with AWS lambda and S3, Textract can be triggered automatically whenever a document is uploaded, enabling real-time processing without the hassle of manging infrastructure. 

# Asynchronous Implementation
We are going to use two lambda functions, the first one will be triggered by file uploads to a source s3 bucket. The second lambda function will be triggered by a Textract event and parse out the results and save the results to a distination bucket.

## The steps
1. Upload: Users upload documents, such as PDFs or scanned images, to an Amazon S3 bucket in the incoming folder.
2. Lambda Trigger via S3 Notification: When a document is uploaded to the S3 bucket, it triggers an AWS Lambda function via an S3 notification.
3. Textract Processing: The triggered Lambda function calls AWS Textract, which processes the document.
4. Lambda Trigger via an event: Once Textract completes the document processing, a cloudwatch event triggers another Lambda function.
5. Post-Processing: he second Lambda function can further process the extracted data by formatting it into a structured format (e.g., JSON, CSV) and storing it in an S3 bucket or a database like Amazon RDS or DynamoDB for easy retrieval and analysis.


