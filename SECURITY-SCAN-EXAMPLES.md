# セキュリティスキャン使用例

このファイルは、Bicep ファイルのセキュリティスキャンの実行方法と結果の例を示します。

## クイックスタート

### 1. ローカルスキャンの実行

```bash
# リポジトリのルートディレクトリで実行
./scripts/scan-bicep-security.sh
```

### 2. GitHub Actions での自動実行

コードをプッシュすると自動的にスキャンが実行されます：

```bash
git add .
git commit -m "Update Bicep templates"
git push origin main
```

GitHub の以下の場所で結果を確認：
- **Actions タブ**: ワークフローの実行状況
- **Security タブ > Code scanning**: 発見された脆弱性の詳細

## スキャン結果の例

### ✅ 問題なし

```
🔒 Bicep セキュリティスキャンを開始します...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1️⃣  Bicep Lint チェック
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Azure CLI が見つかりました

📄 チェック中: main.bicep
  ✅ 構文チェック: 問題なし

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ スキャン完了
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### ⚠️ 警告あり

Bicep Lint で警告が見つかった場合の例：

```
📄 チェック中: main.bicep
  ⚠️  警告が見つかりました:

Warning no-hardcoded-env-urls: Environment URLs should not be hardcoded.
  → Line 98: 'privatelink.blob.core.windows.net'
  → 推奨: environment() 関数を使用

Warning BCP073: The property "tier" is read-only.
  → Line 158: 読み取り専用プロパティへの代入
  → 推奨: このプロパティを削除
```

### ❌ エラーあり

セキュリティ問題が検出された場合の Checkov の例：

```
Check: CKV_AZURE_35: "Ensure storage account uses HTTPS-only traffic"
	FAILED for resource: Microsoft.Storage/storageAccounts.storage
	File: /bicep/main.bicep:153-194
	Guide: https://docs.bridgecrew.io/docs/ensure-storage-for-critical-data-are-encrypted-with-customer-managed-key

Check: CKV_AZURE_43: "Ensure Storage Accounts adhere to the naming rules"
	PASSED for resource: Microsoft.Storage/storageAccounts.storage

Check: CKV_AZURE_59: "Ensure that Storage accounts disallow public access"
	PASSED for resource: Microsoft.Storage/storageAccounts.storage
```

## よくあるスキャン結果と対処方法

### 1. 暗号化の警告

**問題:**
```
Warning: TLS version is below recommended minimum
```

**対処:**
```bicep
properties: {
  minimumTlsVersion: 'TLS1_2'  // TLS 1.2 以上を使用
}
```

### 2. パブリックアクセスの警告

**問題:**
```
Warning: Storage account allows public blob access
```

**対処:**
```bicep
properties: {
  allowBlobPublicAccess: false
  publicNetworkAccess: 'Disabled'
}
```

### 3. ネットワークルールの警告

**問題:**
```
Warning: Network ACL default action is 'Allow'
```

**対処:**
```bicep
properties: {
  networkAcls: {
    defaultAction: 'Deny'
    bypass: 'AzureServices'
  }
}
```

## GitHub Actions ワークフローの手動実行

1. GitHub リポジトリの「Actions」タブを開く
2. 左サイドバーから「Bicep Security Scan」を選択
3. 「Run workflow」ボタンをクリック
4. ブランチを選択して「Run workflow」を実行

## スキャン結果のダウンロード

GitHub Actions の実行ページから SARIF ファイルをダウンロードできます：

1. Actions タブで完了したワークフローを開く
2. 「Artifacts」セクションを確認
3. 以下のファイルをダウンロード：
   - `security-scan-results` - Microsoft Security DevOps の結果
   - `checkov-scan-results` - Checkov の結果
   - `psrule-scan-results` - PSRule の結果

## CI/CD への統合

### プルリクエストでのブロック

プルリクエストで重大な脆弱性が見つかった場合にマージをブロックするには、
GitHub のブランチ保護ルールを設定します：

1. Settings → Branches
2. 保護するブランチのルールを追加
3. 「Require status checks to pass before merging」を有効化
4. 「Bicep Security Scan」を必須チェックに追加

### 通知の設定

セキュリティスキャンで問題が見つかった場合に通知を受け取るには：

1. Settings → Notifications
2. 「Security alerts」を有効化
3. メール/Slack/Teams などで通知を受信

## トラブルシューティング

### スキャンが失敗する

```bash
# ツールのバージョン確認
az --version
bicep --version

# 最新版へのアップデート
az upgrade
az bicep upgrade
```

### Docker の問題

```bash
# Docker が起動しているか確認
docker ps

# Docker イメージの削除と再取得
docker rmi bridgecrew/checkov
docker pull bridgecrew/checkov
```

## 参考情報

- [SECURITY-SCANNING.md](./SECURITY-SCANNING.md) - 詳細なガイド
- [GitHub Code Scanning](https://docs.github.com/ja/code-security/code-scanning)
- [Azure Bicep Best Practices](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/best-practices)
