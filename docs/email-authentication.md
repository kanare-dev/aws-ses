# メール認証の仕組み: SPF, DKIM, DMARC

メールのなりすまし（スプーフィング）を防ぎ、送信元の正当性を証明するための3つの認証技術について解説する。

## 概要

```
送信者 → メールサーバー → 受信サーバー → 受信者
                              ↓
                    SPF/DKIM/DMARCを検証
```

| 技術 | 目的 | 検証対象 |
| --- | --- | --- |
| SPF | 送信サーバーの認可 | IPアドレス |
| DKIM | メール内容の改ざん検知 | 電子署名 |
| DMARC | SPF/DKIMの結果に基づくポリシー | ドメインの整合性 |

---

## SPF (Sender Policy Framework)

### 概要

SPFは「このドメインからメールを送信できるサーバー」を宣言する仕組み。
DNSのTXTレコードに許可するIPアドレスやホスト名を記載する。

### 仕組み

```
1. 送信者が noreply@notify.kanare.dev からメール送信
2. 受信サーバーが notify.kanare.dev のSPFレコードを参照
3. 送信元IPがSPFレコードに含まれているか確認
4. 含まれていれば PASS、なければ FAIL
```

### レコード例

```
v=spf1 include:amazonses.com ~all
```

| 要素 | 説明 |
| --- | --- |
| `v=spf1` | SPFバージョン1 |
| `include:amazonses.com` | Amazon SESのサーバーを許可 |
| `~all` | 上記以外はソフトフェイル（疑わしいが拒否しない） |

### 修飾子

| 修飾子 | 意味 |
| --- | --- |
| `+all` | 全て許可（非推奨） |
| `-all` | 上記以外は拒否（ハードフェイル） |
| `~all` | 上記以外は疑わしい（ソフトフェイル） |
| `?all` | 中立（判断しない） |

---

## DKIM (DomainKeys Identified Mail)

### 概要

DKIMはメールに電子署名を付与し、送信元の正当性と内容の改ざんがないことを証明する。
秘密鍵で署名し、DNSに公開鍵を置いて受信側が検証する。

### 仕組み

```
1. 送信サーバーが秘密鍵でメールヘッダー/本文を署名
2. 署名を DKIM-Signature ヘッダーとして付与
3. 受信サーバーが送信ドメインのDNSから公開鍵を取得
4. 公開鍵で署名を検証
5. 検証成功なら PASS
```

### メールヘッダー例

```
DKIM-Signature: v=1; a=rsa-sha256; d=notify.kanare.dev; s=xxxxxxxx;
    h=from:to:subject:date;
    bh=base64encodedBodyHash;
    b=base64encodedSignature
```

| 要素 | 説明 |
| --- | --- |
| `v=1` | DKIMバージョン |
| `a=rsa-sha256` | 署名アルゴリズム |
| `d=notify.kanare.dev` | 署名ドメイン |
| `s=xxxxxxxx` | セレクタ（公開鍵を識別） |
| `h=from:to:...` | 署名対象のヘッダー |
| `bh=...` | 本文のハッシュ |
| `b=...` | 署名本体 |

### DNSレコード例

```
selector._domainkey.notify.kanare.dev. IN CNAME selector.dkim.amazonses.com.
```

AWS SESの場合、CNAMEレコードでAmazonの公開鍵を参照する。

---

## DMARC (Domain-based Message Authentication, Reporting & Conformance)

### 概要

DMARCはSPFとDKIMの検証結果を基に、認証失敗時の処理方法を指定する。
また、認証結果のレポートを受け取ることができる。

### 仕組み

```
1. 受信サーバーがSPFとDKIMを検証
2. DMARCアライメント（ドメイン一致）を確認
3. DMARCポリシーに従って処理
4. 送信者にレポートを送信（設定時）
```

### アライメント

DMARCは「ヘッダーFrom」と「SPF/DKIMのドメイン」が一致するか確認する。

```
ヘッダーFrom: noreply@notify.kanare.dev
SPF検証ドメイン: notify.kanare.dev     → 一致 ✓
DKIM署名ドメイン: notify.kanare.dev   → 一致 ✓
```

### レコード例

```
v=DMARC1; p=quarantine; rua=mailto:dmarc@notify.kanare.dev
```

| 要素 | 説明 |
| --- | --- |
| `v=DMARC1` | DMARCバージョン |
| `p=quarantine` | ポリシー（迷惑メールフォルダへ） |
| `rua=mailto:...` | 集計レポートの送信先 |

### ポリシー

| ポリシー | 動作 |
| --- | --- |
| `p=none` | 何もしない（監視のみ） |
| `p=quarantine` | 迷惑メールフォルダへ振り分け |
| `p=reject` | 受信拒否 |

### 推奨される導入手順

1. `p=none` で開始し、レポートを監視
2. 問題がなければ `p=quarantine` に変更
3. 安定したら `p=reject` に移行

---

## 本プロジェクトでの設定

`cloudflare.tf` で以下のレコードを作成している：

### SPF

```hcl
# notify.kanare.dev (送信ドメイン)
resource "cloudflare_record" "root_spf" {
  name    = var.domain
  type    = "TXT"
  content = "v=spf1 include:amazonses.com ~all"
}
```

### DKIM

```hcl
resource "cloudflare_record" "ses_dkim" {
  count   = 3
  name    = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}._domainkey.${var.domain}"
  type    = "CNAME"
  content = "${aws_ses_domain_dkim.main.dkim_tokens[count.index]}.dkim.amazonses.com"
}
```

### DMARC

```hcl
resource "cloudflare_record" "dmarc" {
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  content = "v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.domain}"
}
```

---

## 検証方法

### コマンドラインで確認

```bash
# SPF
dig TXT notify.kanare.dev

# DKIM
dig CNAME selector._domainkey.notify.kanare.dev

# DMARC
dig TXT _dmarc.notify.kanare.dev
```

### オンラインツール

- [MXToolbox](https://mxtoolbox.com/) - DNS/メール設定の総合チェック
- [Mail Tester](https://www.mail-tester.com/) - テストメールのスコアリング
- [DMARC Analyzer](https://www.dmarcanalyzer.com/) - DMARCレポートの分析

---

## 参考リンク

- [RFC 7208 - SPF](https://datatracker.ietf.org/doc/html/rfc7208)
- [RFC 6376 - DKIM](https://datatracker.ietf.org/doc/html/rfc6376)
- [RFC 7489 - DMARC](https://datatracker.ietf.org/doc/html/rfc7489)
- [AWS SES - Email authentication](https://docs.aws.amazon.com/ses/latest/dg/email-authentication.html)
