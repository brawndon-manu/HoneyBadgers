locals {
  common_tags = {
    Project = var.project_name
    Env     = var.env
  }
}

# Trust policy so AWS Lambda can assume this role
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Execution role for the log parser Lambda
resource "aws_iam_role" "parser_lambda_role" {
  name               = "${var.project_name}-${var.env}-parser-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

# Permissions for parser Lambda:
# - write/update items in the ThreatIntel table
# - write its own CloudWatch Logs
data "aws_iam_policy_document" "parser_lambda_policy" {
  statement {
    sid    = "AllowWriteThreatIntel"
    effect = "Allow"

    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:DescribeTable",
    ]

    resources = [var.threatintel_table_arn]
  }

  statement {
    sid    = "AllowBasicLogWrite"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "parser_lambda_policy" {
  name   = "${var.project_name}-${var.env}-parser-lambda-policy"
  policy = data.aws_iam_policy_document.parser_lambda_policy.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "parser_lambda_role_attach" {
  role       = aws_iam_role.parser_lambda_role.name
  policy_arn = aws_iam_policy.parser_lambda_policy.arn
}

# Execution role for the WAF automation Lambda
resource "aws_iam_role" "waf_lambda_role" {
  name               = "${var.project_name}-${var.env}-waf-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = local.common_tags
}

# Permissions for WAF automation Lambda:
# - read from ThreatIntel table
# - manage WAFv2 IPSets (regional)
data "aws_iam_policy_document" "waf_lambda_policy" {
  statement {
    sid    = "AllowReadThreatIntel"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:DescribeTable",
    ]

    resources = [var.threatintel_table_arn]
  }

  statement {
    sid    = "AllowManageWafIpSets"
    effect = "Allow"

    actions = [
      "wafv2:GetIPSet",
      "wafv2:UpdateIPSet",
      "wafv2:ListIPSets",
    ]

    # Regional WAFv2 IPSets
    resources = [
      "arn:aws:wafv2:${var.env == "prod" ? "*" : "*"}:*:regional/ipset/*"
    ]
  }
}

resource "aws_iam_policy" "waf_lambda_policy" {
  name   = "${var.project_name}-${var.env}-waf-lambda-policy"
  policy = data.aws_iam_policy_document.waf_lambda_policy.json
  tags   = local.common_tags
}

resource "aws_iam_role_policy_attachment" "waf_lambda_role_attach" {
  role       = aws_iam_role.waf_lambda_role.name
  policy_arn = aws_iam_policy.waf_lambda_policy.arn
}
