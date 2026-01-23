output "ses_domain_identity_arn" {
  description = "ARN of the SES domain identity"
  value       = aws_ses_domain_identity.main.arn
}

output "ses_verification_token" {
  description = "SES domain verification token"
  value       = aws_ses_domain_identity.main.verification_token
}

output "ses_dkim_tokens" {
  description = "DKIM tokens for SES"
  value       = aws_ses_domain_dkim.main.dkim_tokens
}

output "ses_sender_access_key_id" {
  description = "Access key ID for SES sender IAM user"
  value       = aws_iam_access_key.ses_sender.id
}

output "ses_sender_secret_access_key" {
  description = "Secret access key for SES sender IAM user"
  value       = aws_iam_access_key.ses_sender.secret
  sensitive   = true
}

output "smtp_endpoint" {
  description = "SMTP endpoint for SES"
  value       = "email-smtp.${var.aws_region}.amazonaws.com"
}

output "smtp_username" {
  description = "SMTP username (same as access key ID)"
  value       = aws_iam_access_key.ses_sender.id
}

output "smtp_password" {
  description = "SMTP password (derived from secret access key)"
  value       = aws_iam_access_key.ses_sender.ses_smtp_password_v4
  sensitive   = true
}
