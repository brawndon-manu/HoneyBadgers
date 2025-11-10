resource "aws_dynamodb_table" "this" {
  name         = var.ddb_table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "ip"

  attribute {
    name = "ip"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-threatintel"
  }
}
