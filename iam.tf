# Get current AWS account ID
data "aws_caller_identity" "current" {}

# IAM policy for SES sending
resource "aws_iam_policy" "ses_sender" {
  name        = "ses-sender-policy"
  description = "Policy for sending emails via SES"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = [
          "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/${var.domain}",
          "arn:aws:ses:${var.aws_region}:${data.aws_caller_identity.current.account_id}:identity/noreply@${var.domain}"
        ]
        Condition = {
          StringEquals = {
            "ses:FromAddress" = "noreply@${var.domain}"
          }
        }
      }
    ]
  })
}

# IAM user for application
resource "aws_iam_user" "ses_sender" {
  name = "ses-sender"
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "ses_sender" {
  user       = aws_iam_user.ses_sender.name
  policy_arn = aws_iam_policy.ses_sender.arn
}

# Access key for the user
resource "aws_iam_access_key" "ses_sender" {
  user = aws_iam_user.ses_sender.name
}
