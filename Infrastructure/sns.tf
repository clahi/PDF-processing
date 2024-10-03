resource "aws_iam_role" "snsRole" {
  name = "snsRole"
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
            "textract.amazonaws.com"
          ]
        }
      }
    ]
  })
}

resource "aws_iam_policy" "snsPolicy" {
  name = "snsPolicy"
  policy = jsonencode({
    "Version" : "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sns:*",
        ],
        "Resource" : "*"
      },
    ]
  })
}

resource "aws_iam_policy_attachment" "snsPolicyAttachment" {
  policy_arn = aws_iam_policy.snsPolicy.arn
  roles      = [aws_iam_role.snsRole.name]
  name       = "snsPolicyAttachment"
}

resource "aws_sns_topic" "myTopic" {
  name = "myTopic"
}

resource "aws_sns_topic_subscription" "topic_lambda" {
  topic_arn = aws_sns_topic.myTopic.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.parseTextract.arn
}
