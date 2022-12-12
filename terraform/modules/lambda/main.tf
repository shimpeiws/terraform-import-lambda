resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

resource "aws_lambda_function" "terraform_import_lambda" {
  function_name = "terraform-import-lambda"

  s3_bucket = "${var.lambda_source_bucket}"
  s3_key    = "function.zip"
  handler = "index.handler"
  runtime   = "nodejs18.x"
  timeout   = "300"
  role      = aws_iam_role.iam_for_lambda.arn

  publish = "true"
}
