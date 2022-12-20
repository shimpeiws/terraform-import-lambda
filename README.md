# terraform-import-lambda

## Create Existing Lambda

https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/nodejs-handler.html
https://docs.aws.amazon.com/ja_jp/lambda/latest/dg/nodejs-package.html

```
% cd TO_YOUR_existingLambda_directory
% zip -r function.zip .
  adding: index.js (deflated 14%)
  adding: package-lock.json (deflated 44%)
  adding: package.json (deflated 31%)
% aws lambda update-function-code --function-name terraform-import-lambda --zip-file fileb://function.zip
```

## terraform

### Before run commands

`docker-compose run --rm terraform init`

### import

IAM

`docker-compose run --rm terraform import aws_iam_role.iam_for_lambda arn:aws:iam::YOUR-IAM-ROLE-ARN-HERE`

Lambda

`docker-compose run --rm terraform import module.lambda.aws_lambda_function.terraform_import_lambda YOUUR-LAMBDA-NAME-HERE`

### commands

`docker-compose run --rm terraform init`

`docker-compose run --rm terraform plan`

`docker-compose run --rm terraform apply`

`docker-compose run --rm terraform destroy`
