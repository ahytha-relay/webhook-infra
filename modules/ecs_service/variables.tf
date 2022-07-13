variable "task_family" {
  type = string
  description = "Family that the service belongs to"
}

variable "service_name" {
  type = string
  description = "Name of the service"
}

variable "log_group" {
  type = object({
    name = string
    region = string
  })
  description = "Log group to log to. This should include both the name and region"
}

variable "container_image" {
  type = string
  description = "ECR URL for the container image"
}

variable "container_port" {
  type = number
  description = "Port number exposed in the container image"
}

variable "execution_role_arn" {
  type = string
  description = "Execution role arn for the service deployment process"
}

variable "desired_count" {
  type = number
  description = "The number of task instances desired"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "Private subnet IDs associated with the service"
}

variable "security_group_id" {
  type = string
  description = "ID of the security group the service run within"
}

variable "target_group_id" {
  type = string
  description = "ID of the load balancer target group"
}

variable "cluster_id" {
  type = string
  description = "ID of the cluster this service will run within"
}

variable "service_namespace_id" {
  type = string
  description = "The ID of the service namespace for discovery"
}