terraform {
  required_version = ">= 1.3"

  backend "s3" {
    bucket  = "itau-case-tfstate"
    key     = "terraform-eks/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {

    random = {
      version = "~> 3.0"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.65"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
