resource "aws_iam_role" "lambdaRole" {
  name = "lambdaRole"
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
            "lambda.amazon.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambdaS3Policy" {
  name = "lambdaS3Policy"
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
        Effect: "Allow",
        Action: [
            "s3:GetObject",
            "s3:PutObject"
        ],
        Resource: "arn:aws:s3:::my-bucket-serverless-src-and-dest/*"
      },
      {
            "Effect": "Allow",
            "Action": [
                "textract:*"
            ],
            "Resource": "*"
        }
    ]
  })
}

resource "aws_iam_policy_attachment" "lambdaRolePolicyAttachment" {
  policy_arn = aws_iam_policy.lambdaS3Policy.arn
  roles = [aws_iam_role.lambdaRole]
  name = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambda_file" {
  type = "zip"
  source_file = "${path.module}/pdfProcessing.py"
  output_path = "${path.module}/pdfProcessing.zip"
}

resource "aws_lambda_function" "pdf-processor" {
  role = aws_iam_role.lambdaRole.arn
  filename = data.archive_file.lambda_file.output_path
  source_code_hash = data.archive_file.lambda_file.output_base64sha256
  function_name = "pdfProcessing"
  timeout = 60
  runtime = "python3.9"
  handler = "pdfProcessing.lambda.lambda_handler"
}


resource "aws_lambda_permission" "pdf-processor-permission" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pdf-processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn = aws_s3_bucket.my_bucket.arn
}

resource "aws_s3_bucket_notification" "bucketNotification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.pdf-processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "source/"
  }

  depends_on = [ aws_lambda_permission.pdf-processor-permission ]
}
