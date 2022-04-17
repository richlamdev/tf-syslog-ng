provider "aws" {
  region  = var.aws_region
  profile = "cloud_user"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "default_tags" {
  type        = map(any)
  description = "Map of Default Tags"
}
