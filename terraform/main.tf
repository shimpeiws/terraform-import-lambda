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
  source               = "./modules/lambda"
  lambda_source_bucket = "terraform-import-lambda-source"
}

module "code-pipeline" {
  source                         = "./modules/code-pipeline"
  code_build_project_name        = "terrafom-import-code-pipeline"
  code_pipeline_project_name     = "terrafom-import-code-pipeline"
  github_project_url             = "https://github.com/shimpeiws/terraform-import-lambda"
  github_account_name            = "shimpeiws"
  github_oauth_token             = var.github_oauth_token
  github_repo_name               = "terraform-import-lambda"
  github_branch_name             = "main"
  build_buildspec_path           = "./code-build/build-build-spec.yml"
  deploy_buildspec_path          = "./code-build/deploy-build-spec.yml"
  terraform_apply_buildspec_path = "./code-build/terraform-appy-build-spec.yml"
}
