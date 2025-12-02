locals {
  health_common_tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-health"
  }
}

data "archive_file" "health_zip" {
  type = "zip"

  # Root module:  infra/envs/dev  => ${path.root}
  # Repo root:    HoneyBadgers    => ${path.root}/../..
  # Code folder:  lambdas/health  => ${path.root}/../../../lambdas/health
  source_dir  = "${path.root}/../../../lambdas/health"
  output_path = "${path.module}/build/health.zip"
}

resource "aws_lambda_function" "health" {
  function_name = "${var.project_name}-${var.env}-health"
  role          = var.parser_lambda_role_arn

  handler = "app.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.health_zip.output_path
  source_code_hash = data.archive_file.health_zip.output_base64sha256

  timeout     = 10
  memory_size = 128
  publish     = false
  description = "Health check endpoint Lambda."

  environment {
    variables = {
      ENV     = var.env
      PROJECT = var.project_name
    }
  }

  tags = local.health_common_tags
}