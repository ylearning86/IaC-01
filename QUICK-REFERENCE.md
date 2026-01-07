# クイックリファレンス: Bicep セキュリティスキャン

## 🚀 すぐに始める

### 1. リポジトリをクローン
```bash
git clone https://github.com/ylearning86/IaC-01.git
cd IaC-01
```

### 2. ローカルでスキャンを実行
```bash
./scripts/scan-bicep-security.sh
```

### 3. 結果を確認
スクリプトが以下をチェックします：
- ✅ Bicep 構文
- ✅ セキュリティ脆弱性
- ✅ Azure ベストプラクティス

## 📋 よく使うコマンド

### Bicep Lint のみ実行
```bash
az bicep build --file bicep/main.bicep
```

### Checkov のみ実行（Docker）
```bash
docker run --rm -v "$(pwd)":/tf bridgecrew/checkov -d /tf/bicep --framework bicep
```

### GitHub Actions を手動実行
1. GitHub リポジトリの「Actions」タブを開く
2. 「Bicep Security Scan」を選択
3. 「Run workflow」をクリック

## 🔍 スキャン結果の見方

### ✅ 成功
```
✅ 構文チェック: 問題なし
```
→ そのままデプロイ可能

### ⚠️ 警告
```
Warning: Storage account public access enabled
```
→ 修正を推奨（デプロイは可能）

### ❌ エラー
```
Error: TLS version below minimum
```
→ 修正が必要

## 📚 ドキュメント

| ドキュメント | 内容 |
|------------|------|
| [SECURITY-SCANNING.md](./SECURITY-SCANNING.md) | 完全ガイド（詳細） |
| [SECURITY-SCAN-EXAMPLES.md](./SECURITY-SCAN-EXAMPLES.md) | 実用例とトラブルシューティング |
| [IMPLEMENTATION-SUMMARY.md](./IMPLEMENTATION-SUMMARY.md) | 実装内容の要約 |
| [README.md](./README.md) | リポジトリの概要 |

## 🛠️ トラブルシューティング

### スキャンスクリプトが実行できない
```bash
chmod +x scripts/scan-bicep-security.sh
```

### Azure CLI がない
```bash
# Linux
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# macOS
brew install azure-cli

# Windows
winget install Microsoft.AzureCLI
```

### Checkov がない
```bash
# Python pip
pip install checkov

# Docker（推奨）
docker pull bridgecrew/checkov
```

## 💡 ヒント

### コミット前にスキャン
```bash
# pre-commit フックを設定
cat > .git/hooks/pre-commit << 'EOF'
#!/bin/bash
./scripts/scan-bicep-security.sh
EOF
chmod +x .git/hooks/pre-commit
```

### CI/CD で必須化
GitHub のブランチ保護ルールで「Bicep Security Scan」を必須チェックに設定

### 定期的なスキャン
- 週1回、main ブランチで手動実行を推奨
- 新しい脆弱性データベースで再チェック

## 🎯 次のステップ

1. ✅ ローカルスキャンの実行
2. ✅ 警告の確認と修正
3. ✅ GitHub へのプッシュ
4. ✅ 自動スキャン結果の確認
5. ✅ Security タブでトレンド分析

## 📞 サポート

問題や質問がある場合は、Issue を作成してください：
https://github.com/ylearning86/IaC-01/issues
