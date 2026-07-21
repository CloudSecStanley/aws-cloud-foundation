# General variables for the Terraform configuration

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

# VPC and Subnet variables

variable "vpc_cidr" {
    description = "The CIDR block for the VPC"
    type        = string
    default     = "10.0.0.0/16"
}

variable "private_subnet_cidr" {
    description = "The CIDR block for the private subnet"
    type        = string
    default     = "10.0.1.0/24"
}

variable "public_cidr_1" {
    description = "The CIDR block for the public subnet 1"
    type = string
    default = "10.0.2.0/24"
}

variable "public_cidr_2" {
    description = "The CIDR block for the public subnet 2"
    type = string
    default = "10.0.3.0/24"
}

# Instance variables 

variable "instance_type" {
    description = "The EC2 instance type for the compute resources"
    type        = string
    default     = "t3.micro"
}

variable "ami_name_filter" {
    description = "The name filter for the AMI to use for EC2 instances"
    type        = string
    default     = "al2023-ami-2023.*-x86_64"
}

variable "root_volume_size" {
    description = "The size of the root volume for EC2 instances (in GB)"
    type        = number
    default     = 10
}

variable "root_volume_type" {
    description = "The type of the root volume for EC2 instances"
    type        = string
    default     = "gp3"
}

# DOMAIN & CERTIFICATE VARIABLES

variable "domain_name" {
  type        = string
  description = "The primary domain name for the ALB certificate"
  default     = "app.sandbox.internal"
}

variable "alb_certificate_arn" {
  type        = string
  description = "Optional override for an existing ACM Certificate ARN"
  default     = null
}