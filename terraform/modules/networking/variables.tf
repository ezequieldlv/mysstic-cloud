variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "environment" {
  type = string
}
variable "project_name" {
  type = string
}