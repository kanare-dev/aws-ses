# AWS SES with Cloudflare DNS

Terraformを使用してAWS SESとCloudflare DNSを設定し、`noreply@notify.kanare.dev`からメールを送信できるようにする。

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

# (任意) direnv を使う場合
cp .envrc.example .envrc
direnv allow

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

## セキュリティ（公開リポジトリにする前に）

- **絶対にコミットしない**: `terraform.tfvars` / `terraform.tfstate*`（`tfstate` には IAM の secret access key や `smtp_password` 等が保存されます）
- **漏洩が疑われる場合の対応**:
  - Cloudflare API Token を **revoke/再発行**
  - AWS IAM の Access Key を **無効化して再発行**（または `ses-sender` ユーザー自体を作り直す）
  - もし `tfstate/tfvars` を誤ってコミットした場合は **git履歴からも完全削除**（ファイル削除だけでは不十分）

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

- `_amazonses.notify.kanare.dev` (TXT) - ドメイン検証
- `*._domainkey.notify.kanare.dev` (CNAME x3) - DKIM
- `notify.kanare.dev` (TXT) - SPF
- `_dmarc.notify.kanare.dev` (TXT) - DMARC

## サンドボックス制限の解除

新規SESアカウントはサンドボックスモードで、検証済みメールアドレスにのみ送信可能。
本番利用にはAWSコンソールから制限解除をリクエストする：

1. AWS SESコンソール → Account dashboard
2. "Request production access" をクリック
3. 必要事項を入力して申請
