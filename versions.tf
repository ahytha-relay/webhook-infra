terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
  backend "s3" {
    bucket = "alexhytha"
    key = "terraform/webhook"
    region = "us-east-1"
  }
}

provider "aws" {
  profile = "default"
  region = "us-east-2"
}
