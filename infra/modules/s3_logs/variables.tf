variable "project_name" {
  type        = string
  description = "Project name used for tagging."
}

variable "env" {
  type        = string
  description = "Environment name (e.g., dev, prod)."
}

variable "aws_region" {
  type        = string
  description = "AWS region where the log bucket will live."
}

variable "logs_bucket_name" {
  type        = string
  description = "Name of the S3 bucket used for logs (must be globally unique)."
}

variable "enable_versioning" {
  type        = bool
  description = "Whether to enable versioning on the logs bucket."
  default     = true
}

variable "lifecycle_transition_days" {
  type        = number
  description = "Days before transitioning log objects to a cheaper storage class."
  default     = 90
}

variable "lifecycle_expiration_days" {
  type        = number
  description = "Days before expiring log objects."
  default     = 365
}
