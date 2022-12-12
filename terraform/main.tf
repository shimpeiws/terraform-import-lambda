terraform {
  required_providers {
    google = {
      source  = "hashicorp/aws"
      version = "4.46.0"
    }
  }
  backend "s3" {
    bucket = "terraform-import-lambda"
    key    = "terraform.tfstate"
  }
}

module "lambda" {
  source    = "./modules/lambda"
  lambda_source_bucket = "terraform-import-lambda-source"
}
