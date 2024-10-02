data "archive_file" "lambdaTextractFile" {
  type = "zip"
  source_file = "${path.module}/parseTextract.py"
  output_path = "${path.module}/parseTextract.zip"
}

resource "aws_lambda_function" "parse-textract" {
  role = aws_iam_role.lambdaRole.arn
  filename = data.archive_file.lambdaTextractFile.output_path
  source_code_hash = data.archive_file.lambdaTextractFile.output_base64sha256
  function_name = "parseTextract"
  timeout = 60
  runtime = "python3.9"
  handler = "parseTextract.lambda_handler"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.my_bucket.id
    }
  }
}