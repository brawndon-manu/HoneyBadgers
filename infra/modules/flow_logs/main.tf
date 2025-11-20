locals {
  name_prefix = "${var.project_name}-${var.env}-flow-logs"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "flow_logs" {
  name               = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${local.name_prefix}-role"
  }
}

data "aws_iam_policy_document" "flow_logs_to_cw" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "flow_logs" {
  name   = "${local.name_prefix}-policy"
  role   = aws_iam_role.flow_logs.id
  policy = data.aws_iam_policy_document.flow_logs_to_cw.json
}

data "aws_cloudwatch_log_group" "this" {
  name = var.log_group_name
}

resource "aws_flow_log" "vpc" {
  vpc_id = var.vpc_id

  traffic_type = var.traffic_type

  log_destination_type = "cloud-watch-logs"
  log_destination      = data.aws_cloudwatch_log_group.this.arn
  iam_role_arn         = aws_iam_role.flow_logs.arn

  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = local.name_prefix
  }
}
