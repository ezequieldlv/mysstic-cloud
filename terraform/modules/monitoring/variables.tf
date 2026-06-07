variable "telegram_token" { 
    type = string 
    sensitive = true  
}
variable "telegram_chat_id" { 
    type = string 
    sensitive = true  
}
variable "ec2_instance_id" { type = string }