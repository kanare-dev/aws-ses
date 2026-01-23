# SESを使ったメール送信ガイド

Terraformで構築したSES環境からメールを送信する手順。

## 前提条件

- Terraformの適用が完了している
- DNSレコードが伝播している（最大72時間）
- AWS SESのドメイン検証が完了している

## 1. 検証状態の確認

### AWSコンソールで確認

1. [AWS SESコンソール](https://console.aws.amazon.com/ses/) にアクセス
2. 左メニュー「Verified identities」を選択
3. `kanare.dev` のステータスが「Verified」になっていることを確認

### CLIで確認

```bash
aws ses get-identity-verification-attributes \
  --identities kanare.dev \
  --region ap-northeast-1
```

期待する出力：
```json
{
  "VerificationAttributes": {
    "kanare.dev": {
      "VerificationStatus": "Success"
    }
  }
}
```

## 2. サンドボックス制限

### 制限内容

新規SESアカウントはサンドボックスモードで以下の制限がある：

| 項目 | 制限 |
| --- | --- |
| 送信先 | 検証済みメールアドレスのみ |
| 送信数 | 24時間で200通 |
| 送信レート | 1秒あたり1通 |

### テスト用メールアドレスの検証

サンドボックス内でテストするには、送信先のメールアドレスを検証する：

```bash
aws ses verify-email-identity \
  --email-address your-email@example.com \
  --region ap-northeast-1
```

確認メールが届くので、リンクをクリックして検証を完了する。

### 本番アクセスのリクエスト

1. [AWS SESコンソール](https://console.aws.amazon.com/ses/) → Account dashboard
2. 「Request production access」をクリック
3. 以下を入力：
   - Mail type: Transactional（認証メールの場合）
   - Website URL: アプリケーションのURL
   - Use case description: 利用目的を詳細に記載

審査には通常1〜2営業日かかる。

## 3. 認証情報の取得

Terraformの出力から認証情報を取得：

```bash
# SMTPエンドポイント
terraform output smtp_endpoint

# SMTPユーザー名
terraform output smtp_username

# SMTPパスワード
terraform output smtp_password
```

## 4. メール送信方法

### 方法A: SMTP経由

多くのアプリケーションフレームワークで利用可能。

**接続情報：**

| 項目 | 値 |
| --- | --- |
| Host | `email-smtp.ap-northeast-1.amazonaws.com` |
| Port | 587 (STARTTLS) または 465 (TLS) |
| Username | `terraform output smtp_username` の値 |
| Password | `terraform output smtp_password` の値 |

#### Node.js (Nodemailer)

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransport({
  host: 'email-smtp.ap-northeast-1.amazonaws.com',
  port: 587,
  secure: false,
  auth: {
    user: process.env.SMTP_USERNAME,
    pass: process.env.SMTP_PASSWORD,
  },
});

await transporter.sendMail({
  from: 'noreply@kanare.dev',
  to: 'recipient@example.com',
  subject: 'テストメール',
  text: 'これはテストメールです。',
  html: '<p>これはテストメールです。</p>',
});
```

#### Python (smtplib)

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import os

msg = MIMEMultipart('alternative')
msg['Subject'] = 'テストメール'
msg['From'] = 'noreply@kanare.dev'
msg['To'] = 'recipient@example.com'

text = 'これはテストメールです。'
html = '<p>これはテストメールです。</p>'

msg.attach(MIMEText(text, 'plain'))
msg.attach(MIMEText(html, 'html'))

with smtplib.SMTP('email-smtp.ap-northeast-1.amazonaws.com', 587) as server:
    server.starttls()
    server.login(os.environ['SMTP_USERNAME'], os.environ['SMTP_PASSWORD'])
    server.sendmail(msg['From'], msg['To'], msg.as_string())
```

### 方法B: AWS SDK経由

IAMユーザーのアクセスキーを使用。

#### Node.js (AWS SDK v3)

```javascript
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

const client = new SESClient({ region: 'ap-northeast-1' });

const command = new SendEmailCommand({
  Source: 'noreply@kanare.dev',
  Destination: {
    ToAddresses: ['recipient@example.com'],
  },
  Message: {
    Subject: { Data: 'テストメール' },
    Body: {
      Text: { Data: 'これはテストメールです。' },
      Html: { Data: '<p>これはテストメールです。</p>' },
    },
  },
});

await client.send(command);
```

#### Python (boto3)

```python
import boto3

client = boto3.client('ses', region_name='ap-northeast-1')

response = client.send_email(
    Source='noreply@kanare.dev',
    Destination={
        'ToAddresses': ['recipient@example.com'],
    },
    Message={
        'Subject': {'Data': 'テストメール'},
        'Body': {
            'Text': {'Data': 'これはテストメールです。'},
            'Html': {'Data': '<p>これはテストメールです。</p>'},
        },
    },
)
```

### 方法C: AWS CLIでテスト送信

```bash
aws ses send-email \
  --from noreply@kanare.dev \
  --to recipient@example.com \
  --subject "テストメール" \
  --text "これはテストメールです。" \
  --region ap-northeast-1
```

## 5. 環境変数の設定例

### .env ファイル

```bash
# SMTP設定
SMTP_HOST=email-smtp.ap-northeast-1.amazonaws.com
SMTP_PORT=587
SMTP_USERNAME=your-smtp-username
SMTP_PASSWORD=your-smtp-password
MAIL_FROM=noreply@kanare.dev
```

### 環境変数のエクスポート

```bash
export SMTP_USERNAME=$(terraform output -raw smtp_username)
export SMTP_PASSWORD=$(terraform output -raw smtp_password)
```

## 6. トラブルシューティング

### メールが届かない

1. **ドメイン検証の確認**
   ```bash
   aws ses get-identity-verification-attributes \
     --identities kanare.dev --region ap-northeast-1
   ```

2. **DNSレコードの確認**
   ```bash
   dig TXT _amazonses.kanare.dev
   dig TXT _dmarc.kanare.dev
   ```

3. **サンドボックス制限の確認**
   - 送信先が検証済みか確認
   - AWSコンソールでサンドボックス状態を確認

### 認証エラー

1. **SMTP認証情報の確認**
   - `smtp_password` は通常のシークレットキーとは異なる
   - `terraform output smtp_password` で取得した値を使用

2. **IAM権限の確認**
   ```bash
   aws iam get-user-policy --user-name ses-sender --policy-name ses-sender-policy
   ```

### 迷惑メールに振り分けられる

1. SPF/DKIM/DMARCが正しく設定されているか確認
2. [Mail Tester](https://www.mail-tester.com/) でスコアを確認
3. 送信元ドメインのレピュテーションを確認

## 7. 送信統計の確認

```bash
aws ses get-send-statistics --region ap-northeast-1
```

AWSコンソールでも確認可能：
SES → Account dashboard → Sending statistics
