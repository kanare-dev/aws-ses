# Domain verification TXT record
resource "cloudflare_record" "ses_verification" {
  zone_id = var.cloudflare_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  content = aws_ses_domain_identity.main.verification_token
  ttl     = 300
}

# DKIM CNAME records (3 records)
resource "cloudflare_record" "ses_dkim" {
  count   = 3
  zone_id = var.cloudflare_zone_id
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain}"
  type    = "CNAME"
  content = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"
  ttl     = 300
}

# Mail From MX record
resource "cloudflare_record" "ses_mail_from_mx" {
  zone_id  = var.cloudflare_zone_id
  name     = "mail.${var.domain}"
  type     = "MX"
  content  = "feedback-smtp.${var.aws_region}.amazonses.com"
  priority = 10
  ttl      = 300
}

# Mail From SPF record
resource "cloudflare_record" "ses_mail_from_spf" {
  zone_id = var.cloudflare_zone_id
  name    = "mail.${var.domain}"
  type    = "TXT"
  content = "v=spf1 include:amazonses.com ~all"
  ttl     = 300
}

# Root domain SPF record (if not already exists)
resource "cloudflare_record" "root_spf" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain
  type    = "TXT"
  content = "v=spf1 include:amazonses.com ~all"
  ttl     = 300
}

# DMARC record for email authentication
resource "cloudflare_record" "dmarc" {
  zone_id = var.cloudflare_zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}"
  ttl     = 300
}
