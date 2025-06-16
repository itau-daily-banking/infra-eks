variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "default_vpc_id" {
  description = "Default VPC ID"
  type = string
  default = "vpc-0e69c256e36852d32"
}

variable "aws_subnet_1a_id" {
  description = "AWS subnet-1a ID"
  type = string
  default = "subnet-02183af4aefcfc723"
}

variable "aws_subnet_1b_id" {
  description = "AWS subnet-1b ID"
  type = string
  default = "subnet-03f723843f893b9c9"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type = string
  default = "011706314791"
}