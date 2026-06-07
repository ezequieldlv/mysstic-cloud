terraform {
  backend "s3" {
    bucket         = "mysstic-warden-tfstate-ez"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "mysstic-terraform-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

module "networking" {
  source       = "./modules/networking"
  vpc_cidr     = "10.0.0.0/16"
  environment  = "DevSecOps"
  project_name = "mysstic"
}

module "compute" {
  source             = "./modules/compute"
  vpc_id             = module.networking.vpc_id
  public_subnet_id   = module.networking.public_subnet_id
  project_name       = "mysstic"
  tailscale_auth_key = var.tailscale_auth_key
}

module "database" {
  source                = "./modules/database"
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  ec2_security_group_id = module.compute.ec2_security_group_id
  project_name          = "mysstic"
}

module "dns" {
  source        = "./modules/dns"
  domain_name   = "ez-lab.site"
  ec2_public_ip = module.compute.ec2_public_ip
}

module "monitoring" {
  source           = "./modules/monitoring"
  telegram_token   = var.telegram_token
  telegram_chat_id = var.telegram_chat_id
  ec2_instance_id  = module.compute.ec2_instance_id
}