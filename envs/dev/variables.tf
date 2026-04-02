variable "region" {
    description = "AWS region"
    type        = string
    default     = "us-east-1"
}

variable "environment" { 
    description = "Environmment name"
    type        = string
}

variable "project_name" {
    description = "Project name for resource naming"
    type        = string
}