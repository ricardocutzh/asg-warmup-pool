resource "aws_iam_role" "lambda_role" {
  name = "${var.identifier}-${terraform.workspace}-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_permissions" {
  name        = "${var.identifier}-${terraform.workspace}-lambda-policy"
  path        = "/"
  description = "IAM policy for lambda ${var.identifier}-${terraform.workspace}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    },
    {
      "Action": [
        "ec2:CreateTags"
      ],
      "Resource": "*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_permissions.arn
}

resource "aws_lambda_function" "termination_lambda" {
  filename      = "./lambda_functions/termination_lambda/termination.zip"
  function_name = "${var.identifier}-${terraform.workspace}-termination-lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.lambda_handler"

  source_code_hash = filebase64sha256("./lambda_functions/termination_lambda/termination.zip")

  runtime = "python3.6"

  environment {
    variables = {
      ENVIRONMENT = terraform.workspace
      IDENTIFIER  = var.identifier
      REGION      = var.region
    }
  }
}

resource "aws_sns_topic" "asg_termination" {
  name = "${var.identifier}-${terraform.workspace}-sns"
}

resource "aws_sns_topic_subscription" "invoke_with_sns" {
  topic_arn = aws_sns_topic.asg_termination.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.termination_lambda.arn
}

resource "aws_lambda_permission" "allow_sns_invoke" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = "${var.identifier}-${terraform.workspace}-termination-lambda"
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.asg_termination.arn
}