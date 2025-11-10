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
