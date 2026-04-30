provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.100.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "s3" {
    bucket  = "sahar-bucketttttt"
    key     = "test/terraform.tfstate"
    region  = "us-west-2"
    encrypt = true
  }
}
