variable "aws_region" {
    description = "The AWS region to deploy resources in"
    type        = string
    default     = "us-east-1"
}

variable "environment" {
    description = "The environment for the deployment (e.g., dev, staging, prod)"
    type        = string
    default     = "sandbox"
}

variable "project_name" {
    description = "The name of the project for tagging purposes"
    type        = string
    default     = "aws-cloud-foundation"
}

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

