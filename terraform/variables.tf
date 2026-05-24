variable "telegram_token" {
  description = "Token del Bot de Telegram"
  type        = string
  sensitive   = true
}

variable "telegram_chat_id" {
  description = "Chat ID de Telegram"
  type        = string
  sensitive   = true
}

variable "tailscale_auth_key" {
  description = "Auth Key de Tailscale"
  type        = string
  sensitive   = true
}