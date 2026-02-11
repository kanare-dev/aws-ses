# SES Domain Identity
resource "aws_ses_domain_identity" "main" {
  domain = var.domain
}

# SES Domain DKIM
resource "aws_ses_domain_dkim" "main" {
  domain = aws_ses_domain_identity.main.domain
}

# SES Email Identity for noreply@notify.kanare.dev
resource "aws_ses_email_identity" "noreply" {
  email = "noreply@${var.domain}"
}
