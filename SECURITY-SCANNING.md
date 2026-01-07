# Bicep ファイルの脆弱性チェックガイド

このドキュメントでは、リポジトリ内の Bicep ファイルのセキュリティ脆弱性をチェックする方法について説明します。

## 目次

- [自動スキャン（推奨）](#自動スキャン推奨)
- [ローカルでのスキャン](#ローカルでのスキャン)
- [使用されるツール](#使用されるツール)
- [スキャン結果の確認方法](#スキャン結果の確認方法)
- [よくある脆弱性と対策](#よくある脆弱性と対策)

## 自動スキャン（推奨）

### GitHub Actions による自動スキャン

リポジトリに GitHub Actions ワークフローが設定されており、以下のタイミングで自動的にセキュリティスキャンが実行されます：

- `main` または `develop` ブランチへのプッシュ時
- プルリクエスト作成時
- 手動実行（Actionsタブから「Bicep Security Scan」を選択）

### スキャン結果の確認

1. **GitHub の Security タブで確認**
   - リポジトリの「Security」タブを開く
   - 「Code scanning」セクションを確認
   - 見つかった脆弱性の詳細を確認できます

2. **Actions タブで確認**
   - リポジトリの「Actions」タブを開く
   - 最新の「Bicep Security Scan」ワークフローを確認
   - 各ジョブの詳細ログを確認できます

3. **アーティファクトのダウンロード**
   - ワークフロー実行ページからスキャン結果（SARIF ファイル）をダウンロード可能
   - 詳細な分析に使用できます

## ローカルでのスキャン

開発中にローカル環境で脆弱性をチェックする方法です。

### クイックスタート

```bash
# スキャンスクリプトを実行
./scripts/scan-bicep-security.sh
```

このスクリプトは以下のツールを使用してスキャンを実行します：
- Bicep Lint（Azure CLI）
- Checkov
- PSRule for Azure

### 個別ツールの使用

#### 1. Bicep Lint（基本的な検証）

```bash
# 単一ファイルのチェック
az bicep build --file bicep/main.bicep

# すべての Bicep ファイルをチェック
for file in bicep/*.bicep; do
  echo "Checking $file"
  az bicep build --file "$file" --stdout > /dev/null
done
```

**必要なもの:**
- [Azure CLI](https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli)

#### 2. Checkov（IaC セキュリティスキャン）

```bash
# Checkov でスキャン
checkov -d bicep/ --framework bicep

# より詳細な出力
checkov -d bicep/ --framework bicep --output cli
```

**必要なもの:**
```bash
# Python pip でインストール
pip install checkov

# または Docker で実行
docker run --rm -v "$(pwd)":/tf bridgecrew/checkov -d /tf/bicep --framework bicep
```

#### 3. PSRule for Azure（Azure ポリシーチェック）

```powershell
# PowerShell で実行
Install-Module -Name PSRule.Rules.Azure -Scope CurrentUser

# スキャン実行
Assert-PSRule -Module PSRule.Rules.Azure -InputPath 'bicep/' -Format File
```

**必要なもの:**
- [PowerShell 7+](https://learn.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell)
- PSRule.Rules.Azure モジュール

## 使用されるツール

### 1. Microsoft Security DevOps (MSDO)

Microsoft が提供する公式のセキュリティスキャンツール。

**特徴:**
- Azure リソースの設定ミスを検出
- ARM テンプレートと Bicep をサポート
- CIS Benchmark、Azure Security Benchmark に準拠

**検出する脆弱性の例:**
- 暗号化されていないストレージアカウント
- 公開アクセスが有効なリソース
- 脆弱な TLS バージョン

### 2. Checkov

Bridgecrew による IaC セキュリティスキャンツール。

**特徴:**
- 1000+ のビルトインポリシー
- CIS、PCI-DSS、HIPAA コンプライアンスチェック
- カスタムポリシーの作成が可能

**検出する脆弱性の例:**
- セキュリティグループの過度に開放されたルール
- ログが無効なリソース
- バックアップが設定されていないリソース

### 3. PSRule for Azure

Microsoft Azure のベストプラクティスをチェックするツール。

**特徴:**
- 400+ の Azure 特化ルール
- Well-Architected Framework に準拠
- カスタムルールの定義が可能

**検出する脆弱性の例:**
- リソース命名規則の違反
- 冗長性の不足
- 監視とアラートの設定不足

## スキャン結果の確認方法

### 重要度レベル

- **Critical/High**: すぐに修正が必要
- **Medium**: できるだけ早く修正を検討
- **Low**: 時間があれば修正

### SARIF ファイルの読み方

SARIF (Static Analysis Results Interchange Format) は、静的解析結果の標準フォーマットです。

```json
{
  "results": [
    {
      "ruleId": "CKV_AZURE_35",
      "level": "error",
      "message": {
        "text": "Ensure storage account uses HTTPS-only"
      },
      "locations": [
        {
          "physicalLocation": {
            "artifactLocation": {
              "uri": "bicep/main.bicep"
            },
            "region": {
              "startLine": 153
            }
          }
        }
      ]
    }
  ]
}
```

## よくある脆弱性と対策

### 1. ストレージアカウントの公開アクセス

**問題:**
```bicep
properties: {
  allowBlobPublicAccess: true  // ❌ 危険
}
```

**対策:**
```bicep
properties: {
  allowBlobPublicAccess: false  // ✅ 推奨
  publicNetworkAccess: 'Disabled'
}
```

### 2. 弱い TLS バージョン

**問題:**
```bicep
properties: {
  minimumTlsVersion: 'TLS1_0'  // ❌ 古いバージョン
}
```

**対策:**
```bicep
properties: {
  minimumTlsVersion: 'TLS1_2'  // ✅ 推奨
}
```

### 3. 暗号化の未設定

**問題:**
```bicep
properties: {
  supportsHttpsTrafficOnly: false  // ❌ HTTP 許可
}
```

**対策:**
```bicep
properties: {
  supportsHttpsTrafficOnly: true  // ✅ HTTPS のみ
  encryption: {
    services: {
      blob: { enabled: true }
      file: { enabled: true }
    }
    keySource: 'Microsoft.Storage'
  }
}
```

### 4. ネットワークアクセス制御の不足

**問題:**
```bicep
properties: {
  networkAcls: {
    defaultAction: 'Allow'  // ❌ すべて許可
  }
}
```

**対策:**
```bicep
properties: {
  networkAcls: {
    defaultAction: 'Deny'  // ✅ デフォルト拒否
    bypass: 'AzureServices'
    virtualNetworkRules: [
      { id: subnet.id }
    ]
  }
}
```

### 5. 監査ログの無効化

**問題:**
```bicep
// ログ設定なし  // ❌
```

**対策:**
```bicep
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'diagnostic-logs'
  properties: {
    logs: [
      {
        category: 'StorageWrite'
        enabled: true
      }
    ]
    workspaceId: logAnalyticsWorkspace.id
  }
}
```

## ベストプラクティス

### コミット前のチェック

```bash
# pre-commit フックを設定
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
echo "Running Bicep security scan..."
./scripts/scan-bicep-security.sh
EOF

chmod +x .git/hooks/pre-commit
```

### CI/CD パイプラインでの必須化

プルリクエストでスキャンに失敗した場合、マージをブロックするように設定することを推奨します。

### 定期的なスキャン

- 週次でセキュリティスキャンを実行
- 新しいルールやポリシーの更新を確認
- 脆弱性データベースの最新情報をチェック

## トラブルシューティング

### スキャンがエラーで失敗する

```bash
# Azure CLI のバージョン確認
az --version

# Bicep のバージョン確認
az bicep version

# 最新版にアップデート
az bicep upgrade
```

### False Positive（誤検知）の対処

特定のルールを無効化する場合：

```bicep
// Checkov の特定チェックをスキップ
//checkov:skip=CKV_AZURE_35:Reason for skipping

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  // ...
}
```

## 参考リンク

- [Azure Bicep 公式ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/)
- [Azure Security Benchmark](https://learn.microsoft.com/ja-jp/security/benchmark/azure/)
- [Checkov ドキュメント](https://www.checkov.io/)
- [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/)
- [Microsoft Security DevOps](https://github.com/microsoft/security-devops-action)

## サポート

質問や問題がある場合は、Issue を作成してください。
