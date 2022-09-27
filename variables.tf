
variable "environment" {
  description = "Project environment"
  type        = string
}

variable "cluster" {
  description = "ECS Cluster"
  type        = map
}

variable "service" {
  description = "ECS Service"
  type        = map
}

variable "task_definition" {
  description = "ECS Task Definition"
  type        = map
}
