variable "vpc_id" { type = string }
variable "public_subnet_id" { type = string }
variable "project_name" { type = string }
variable "tailscale_auth_key" { 
    type = string 
    sensitive = true 
}