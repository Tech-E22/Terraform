terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }
}

# configure provider
provider "aws" {
  region = "us-east-1"
}
