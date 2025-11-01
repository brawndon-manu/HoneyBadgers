terraform {
  backend "s3" {
    bucket         = "honeybadgers-tf-state-dev-usw2"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "honeybadgers-tf-locks-dev"
    encrypt        = true
  }
}

provider "aws" {
  region  = "us-west-2"
  profile = "honeybadgers-dev"
}