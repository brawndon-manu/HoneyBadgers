resource "aws_cloudwatch_log_group" "flowlogs" {
  name              = "/${var.project_name}/${var.env}/vpc-flow-logs"
  retention_in_days = var.cw_log_retention
  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-vpc-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "events" {
  name              = "/${var.project_name}/${var.env}/events"
  retention_in_days = var.cw_log_retention
  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-events"
  }
}
