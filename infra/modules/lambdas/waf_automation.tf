locals {
  waf_automation_common_tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-waf-automation"
  }
}

# Package the WAF automation Lambda code from the repo-level folder into a zip
data "archive_file" "waf_automation_zip" {
  type = "zip"

  # Root module:  HoneyBadgers/infra/envs/dev  => ${path.root}
  # Repo root:    HoneyBadgers                 => ${path.root}/../..
  # Code folder:  HoneyBadgers/lambdas/waf_automation  => ${path.root}/../../../lambdas/waf_automation
  source_dir  = "${path.root}/../../../lambdas/waf_automation"
  output_path = "${path.module}/build/waf_automation.zip"
}

# WAF automation Lambda function
resource "aws_lambda_function" "waf_automation" {
  function_name = "${var.project_name}-${var.env}-waf-automation"
  role          = var.waf_lambda_role_arn

  handler = "app.lambda_handler"
  runtime = "python3.11"

  filename         = data.archive_file.waf_automation_zip.output_path
  source_code_hash = data.archive_file.waf_automation_zip.output_base64sha256

  timeout     = 60
  memory_size = 256
  publish     = false
  description = "Automates WAF IPSet updates based on ThreatIntel data"

  environment {
    variables = {
      THREATINTEL_TABLE = var.threatintel_table_name
      WAF_IPSET_ID      = var.waf_ipset_id
      WAF_IPSET_ARN     = var.waf_ipset_arn
      ENV               = var.env
      PROJECT           = var.project_name
    }
  }

  tags = local.waf_automation_common_tags
}