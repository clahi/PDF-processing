resource "aws_api_gateway_rest_api" "uploadToS3" {
  name = "uploadToS3"

  # Add binary media types
  binary_media_types = [
    "application/pdf"
  ]

  # binary_media_types = [
  #   "multipart/form-data"
  # ]
}

resource "aws_api_gateway_resource" "upload" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id
  parent_id   = aws_api_gateway_rest_api.uploadToS3.root_resource_id
  path_part   = "upload"

}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.uploadToS3.id
  resource_id   = aws_api_gateway_resource.upload.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "post" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  # response_models = {
  #   "application/json" = "Empty"
  # }
}

resource "aws_api_gateway_integration" "lambda_integration_post" {
  rest_api_id             = aws_api_gateway_rest_api.uploadToS3.id
  resource_id             = aws_api_gateway_resource.upload.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambdaUploadToS3.invoke_arn
}

resource "aws_api_gateway_integration_response" "post" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.post.http_method
  status_code = aws_api_gateway_method_response.post.status_code

    # cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Filename,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_method.post,
    aws_api_gateway_integration.lambda_integration_post
  ]
}

resource "aws_api_gateway_method" "options" {
  rest_api_id      = aws_api_gateway_rest_api.uploadToS3.id
  resource_id      = aws_api_gateway_resource.upload.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS integration
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.uploadToS3.id
  resource_id          = aws_api_gateway_resource.upload.id
  http_method          = "OPTIONS"
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  depends_on = [
    aws_api_gateway_method.options,
  ]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id
  resource_id = aws_api_gateway_resource.upload.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"

  # cors
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Filename,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_method.options,
    aws_api_gateway_method_response.post,
    aws_api_gateway_integration.options_integration,
  ]
}




resource "aws_api_gateway_deployment" "deploymet" {
  rest_api_id = aws_api_gateway_rest_api.uploadToS3.id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.uploadToS3.body))
  }

  depends_on = [
    aws_api_gateway_method.post,
    aws_api_gateway_method.options,
    aws_api_gateway_integration.lambda_integration_post,
    aws_api_gateway_integration.options_integration,
  ]


  stage_name = "prod"
}