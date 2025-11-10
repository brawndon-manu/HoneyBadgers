variable "project_name" {
  description = "Project name prefix for CW resources (e.g., HoneyBadgers)"
  type        = string
}

variable "env" {
  description = "Environment (e.g., dev, prod)"
  type        = string
}

variable "cw_log_retention" {
  description = "CloudWatch Logs retention in days"
  type        = number
}
