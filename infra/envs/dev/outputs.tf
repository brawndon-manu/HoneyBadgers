output "vpc_id"                { 
    value = module.vpc.vpc_id 
    }

output "public_subnet_ids"     {
    value = module.vpc.public_subnet_ids 
    }

output "private_subnet_ids"    { 
    value = module.vpc.private_subnet_ids 
    }

output "public_route_table_id" { 
    value = module.vpc.public_route_table_id 
    }

output "igw_id"                { 
    value = module.vpc.igw_id 
    }

output "threatintel_table_name" {
  description = "DynamoDB ThreatIntel table name"
  value       = module.dynamodb.table_name
}

output "threatintel_table_arn" {
  description = "DynamoDB ThreatIntel table ARN"
  value       = module.dynamodb.table_arn
}



