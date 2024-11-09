resource "aws_iam_role" "lambdaRoleS3" {
  name = "lambdaRoleS3"
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

resource "aws_iam_policy" "lambdaPolicyS3" {
  name = "lambdaPolicyForSES"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [{
      "Effect" : "Allow",
      "Action" : [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource" : "arn:aws:logs:*:*:*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:*",
        ],
        "Resource" : "*"
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
  policy_arn = aws_iam_policy.lambdaPolicyS3.arn
  roles      = [aws_iam_role.lambdaRoleS3.name]
  name       = "lambdaRolePolicyAttachment"
}

data "archive_file" "lambdaFile" {
  type        = "zip"
  source_file = "${path.module}/lambdaUploadToS3.py"
  output_path = "${path.module}/lambdaUploadToS3.zip"
}

resource "aws_lambda_function" "lambdaUploadToS3" {
  role             = aws_iam_role.lambdaRoleS3.arn
  filename         = data.archive_file.lambdaFile.output_path
  source_code_hash = data.archive_file.lambdaFile.output_base64sha256
  function_name    = "lambdaUploadToS3"
  timeout          = 60
  runtime          = "python3.9"
  handler          = "lambdaUploadToS3.lambda_handler"

  environment {
    variables = {
      # S3_BUCKET = aws_s3_bucket.my_bucket_source_bucket.id
      S3_BUCKET = "my-bucket-serverless-source-01"
    }
  }
}

resource "aws_lambda_permission" "lambdaPermission" {
  statement_id  = "lambdaPermission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdaUploadToS3.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.uploadToS3.execution_arn}/*"
}