variable "nickname" {
  type = string
  description = "Name to be used to identify this kafka instance"
}

variable "log_region" {
  type = string
  description = "Region to log to"
}

variable "service_namespace_id" {
  type = string
  description = "The ID of the service namespace for discovery"
}

variable "service_namespace_name" {
  type = string
  description = "The service namespace text"
}

variable "execution_role_arn" {
  type = string
  description = "Execution role arn for the service deployment process"
}

variable "private_subnet_ids" {
  type = list(string)
  description = "Private subnet IDs associated with these services"
}

variable "cluster_id" {
  type = string
  description = "ID of the cluster this service will run within"
}