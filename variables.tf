variable "aws_region" {
  description = "AWS region for SES"
  type        = string
  default     = "ap-northeast-1"
}

variable "domain" {
  description = "Domain name for SES"
  type        = string
  default     = "kanare.dev"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain"
  type        = string
}
