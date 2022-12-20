data "aws_iam_policy_document" "code_build_assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "code_build_role" {
  name               = "${var.code_build_project_name}-code-build-role"
  assume_role_policy = data.aws_iam_policy_document.code_build_assume_role_policy.json
}

data "aws_iam_policy_document" "code_build_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "code_build_policy" {
  role   = aws_iam_role.code_build_role.name
  policy = data.aws_iam_policy_document.code_build_policy.json
}

resource "aws_codebuild_source_credential" "github" {
  auth_type   = "PERSONAL_ACCESS_TOKEN"
  server_type = "GITHUB"
  token       = var.github_oauth_token
}


resource "aws_codebuild_project" "build" {
  name          = "${var.code_build_project_name}-build"
  description   = "code build for build"
  build_timeout = "60"
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "node:16.19.0-slim"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  source {
    type            = "GITHUB"
    location        = var.github_project_url
    git_clone_depth = 1
    buildspec       = var.build_buildspec_path
    auth {
      type     = "OAUTH"
      resource = aws_codebuild_source_credential.github.arn
    }
  }
}

resource "aws_codebuild_project" "deploy" {
  name          = "${var.code_build_project_name}-terraform-deploy"
  description   = "code build for deploy"
  build_timeout = "60"
  service_role  = aws_iam_role.code_build_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "node:16.19.0-slim"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  source {
    type            = "GITHUB"
    location        = var.github_project_url
    git_clone_depth = 1
    buildspec       = var.deploy_buildspec_path
    auth {
      type     = "OAUTH"
      resource = aws_codebuild_source_credential.github.arn
    }
  }
}

data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      identifiers = ["codepipeline.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name               = "${var.code_build_project_name}-code-pipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
}

data "aws_iam_policy_document" "code_pipeline_policy" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:PutObject"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "code_pipeline_policy" {
  role   = aws_iam_role.codepipeline_role.name
  policy = data.aws_iam_policy_document.code_pipeline_policy.json
}

resource "aws_s3_bucket" "artifact" {
  bucket = "${var.code_pipeline_project_name}-s3-artifact"
  acl    = "private"
}

data "aws_kms_alias" "s3kmskey" {
  name = "alias/aws/s3"
}

resource "aws_codepipeline" "build_deploy" {
  name     = "${var.code_pipeline_project_name}-pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.artifact.bucket
    type     = "S3"

    encryption_key {
      id   = data.aws_kms_alias.s3kmskey.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        Owner      = var.github_account_name
        OAuthToken = var.github_oauth_token
        Repo       = var.github_repo_name
        Branch     = var.github_branch_name
      }
    }
  }


  stage {
    name = "Build"

    action {
      name            = "Plan"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Approval"

    action {
      name     = "Approval"
      category = "Approval"
      owner    = "AWS"
      provider = "Manual"
      version  = "1"
    }
  }

  stage {
    name = "Apply"

    action {
      name            = "Apply"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.deploy.name
      }
    }
  }
}
