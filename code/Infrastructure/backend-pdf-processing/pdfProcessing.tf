resource "aws_iam_role" "lambda_pdf_processing" {
  name = "lambda-pdf-processing"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow"
        "Action" : [
          "sts:AssumeRole"
        ]
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_s3_pdf_processing_policy" {
  name = "lambda-s3-pdf-processing-policy"
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        Effect : "Allow",
        Action : [
          "s3:*",
        ],
        Resource : "arn:aws:s3:::my-bucket-serverless-source/*",
        Resource : "arn:aws:s3:::my-bucket-serverless-dest-bucket/*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "textract:*"
        ],
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambda_s3_pdf_processing_policy.arn
  roles      = [aws_iam_role.lambda_pdf_processing.name]
  name       = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambda_file" {
  type        = "zip"
  source_file = "${path.module}/pdfProcessing.py"
  output_path = "${path.module}/pdfProcessing.zip"
}

resource "aws_lambda_function" "pdf-processor" {
  role             = aws_iam_role.lambda_pdf_processing.arn
  filename         = data.archive_file.lambda_file.output_path
  source_code_hash = data.archive_file.lambda_file.output_base64sha256
  function_name    = "pdfProcessing"
  timeout          = 60
  runtime          = "python3.9"
  handler          = "pdfProcessing.lambda_handler"

  environment {
    variables = {
      TEXTRACT_NOTIFICATION_TOPIC = aws_sns_topic.myTopic.arn
      TEXTRACT_ROLE_ARN           = aws_iam_role.snsRole.arn
    }
  }
}


resource "aws_lambda_permission" "pdf-processor-permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf-processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.my_bucket.arn
}

resource "aws_s3_bucket_notification" "bucketNotification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf-processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
  }

  depends_on = [aws_lambda_permission.pdf-processor-permission]
}
