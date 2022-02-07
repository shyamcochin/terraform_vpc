terraform {
  required_providers {
    aws = {
      version = ">= 3.73.0"
      source = "hashicorp/aws"
    }
  }
  required_version = "~> 1.0.10"
  #required_version = "~> 1.1.4"
}
