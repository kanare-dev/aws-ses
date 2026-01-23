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
        # NOTE:
        # SES SMTP 経由の送信では、IAMポリシーの Resource を identity ARN に絞ると
        # クライアント/経路によっては権限評価が期待通りにならず、
        # 535 Authentication Credentials Invalid になるケースがあるため "*" を使用する。
        #
        # 送信元の制限をかけたい場合は、まず Supabase 側の From が確実に一致することを
        # 確認した上で、下の Condition を有効化して段階的に締めるのが安全。
        Resource = "*"
        # Condition = {
        #   StringEquals = {
        #     "ses:FromAddress" = "noreply@${var.domain}"
        #   }
        # }
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
