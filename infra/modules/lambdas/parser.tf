locals {
  parser_common_tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-parser"
  }
}

# Package the parser Lambda code from the real repo-level folder into a zip
data "archive_file" "parser_zip" {
  type = "zip"

  # Root module:  HoneyBadgers/infra/envs/dev  => ${path.root}
  # Repo root:    HoneyBadgers                 => ${path.root}/../..
  # Code folder:  HoneyBadgers/lambdas/parser  => ${path.root}/../../../lambdas/parser
  source_dir  = "${path.root}/../../../lambdas/parser"
  output_path = "${path.module}/build/parser.zip"
}

# Parser Lambda function
resource "aws_lambda_function" "parser" {
  function_name = "${var.project_name}-${var.env}-parser"
  role          = var.parser_lambda_role_arn

  handler = "app.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.parser_zip.output_path
  source_code_hash = data.archive_file.parser_zip.output_base64sha256

  timeout     = 30
  memory_size = 256
  publish     = false
  description = "Parses honeypot events from CloudWatch Logs into the ThreatIntel DynamoDB table"

  environment {
    variables = {
      TABLE_NAME = var.threatintel_table_name
      ENV        = var.env
      PROJECT    = var.project_name
    }
  }

  tags = local.parser_common_tags
}

# Allow CloudWatch Logs to invoke the parser Lambda
resource "aws_lambda_permission" "allow_cw_logs_invoke_parser" {
  statement_id  = "AllowCWLogsInvokeParser"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.parser.function_name
  principal     = "logs.${var.aws_region}.amazonaws.com"

  # IMPORTANT: allow all streams in this log group
  source_arn = "${var.events_log_group_arn}:*"
}


# Subscription filter: send events log group -> parser Lambda
resource "aws_cloudwatch_log_subscription_filter" "parser_subscription" {
  name            = "${var.project_name}-${var.env}-parser-subscription"
  log_group_name  = var.events_log_group_name
  filter_pattern  = "" # empty = all log events
  destination_arn = aws_lambda_function.parser.arn

  depends_on = [
    aws_lambda_permission.allow_cw_logs_invoke_parser
  ]
}
