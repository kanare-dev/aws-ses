# AWS SES with Cloudflare DNS

Terraformを使用してAWS SESとCloudflare DNSを設定し、`noreply@kanare.dev`からメールを送信できるようにする。

## 前提条件

- Terraform >= 1.0
- AWS CLI（認証情報設定済み）
- Cloudflare API Token（Zone:DNS:Edit権限）
- Cloudflare Zone ID

## セットアップ

```bash
# 変数ファイルを作成
cp terraform.tfvars.example terraform.tfvars

# terraform.tfvarsを編集してCloudflareの認証情報を設定
vim terraform.tfvars

# 初期化
terraform init

# 確認
terraform plan

# 適用
terraform apply
```

## 出力値の確認

```bash
# SMTP認証情報を取得
terraform output smtp_endpoint
terraform output smtp_username
terraform output smtp_password
```

## 構成

| ファイル | 説明 |
|---------|------|
| `versions.tf` | Terraformとプロバイダーのバージョン |
| `variables.tf` | 入力変数 |
| `ses.tf` | AWS SESリソース |
| `cloudflare.tf` | Cloudflare DNSレコード |
| `iam.tf` | メール送信用IAMユーザー |
| `outputs.tf` | 出力値 |

## DNSレコード

Terraformにより以下のDNSレコードがCloudflareに作成される：

- `_amazonses.kanare.dev` (TXT) - ドメイン検証
- `*._domainkey.kanare.dev` (CNAME x3) - DKIM
- `mail.kanare.dev` (MX) - Mail From
- `mail.kanare.dev` (TXT) - SPF
- `kanare.dev` (TXT) - SPF
- `_dmarc.kanare.dev` (TXT) - DMARC

## サンドボックス制限の解除

新規SESアカウントはサンドボックスモードで、検証済みメールアドレスにのみ送信可能。
本番利用にはAWSコンソールから制限解除をリクエストする：

1. AWS SESコンソール → Account dashboard
2. "Request production access" をクリック
3. 必要事項を入力して申請
