variable "environment" {
    description = "Name of the environment"
    type        = string

}

variable "project_name" { 
    description = "Project name for resource naming"
    type        = string
}

variable "tags" { 
    description = "Tags to apply to all resources"
    type        = map(string)
    default     = {}
}