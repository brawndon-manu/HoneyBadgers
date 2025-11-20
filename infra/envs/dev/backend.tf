terraform {
  backend "s3" {
    bucket       = "honeybadgers-tf-state-dev-usw2"
    key          = "dev/terraform.tfstate"
    region       = "us-west-2"
    use_lockfile = true #S3 native locking replacing dynamodb_table
    encrypt      = true
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "honeybadgers-dev"
}