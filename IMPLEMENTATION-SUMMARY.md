# 実装完了: Bicep ファイルの脆弱性チェック機能

## 📋 概要

このリポジトリに Bicep ファイルのセキュリティ脆弱性をチェックする包括的な機能を実装しました。

## ✅ 実装内容

### 1. 自動セキュリティスキャン（GitHub Actions）

**ファイル**: `.github/workflows/bicep-security-scan.yml`

以下の3つのスキャンツールを統合したワークフローを実装：

- **Microsoft Security DevOps (MSDO)**: Azure 公式のセキュリティスキャン
- **Checkov**: IaC セキュリティベストプラクティスチェック
- **PSRule for Azure**: Azure Well-Architected Framework 準拠チェック

**トリガー条件**:
- `main` または `develop` ブランチへのプッシュ時
- プルリクエスト作成時（Bicep ファイル変更時）
- 手動実行（`workflow_dispatch`）

**結果の保存先**:
- GitHub Security タブ（Code scanning）
- ワークフローアーティファクト（SARIF ファイル）

### 2. ローカルスキャンスクリプト

**ファイル**: `scripts/scan-bicep-security.sh`

開発者がローカル環境で実行できるセキュリティスキャンスクリプト。

**機能**:
- Bicep Lint（Azure CLI）による構文チェック
- Checkov による IaC セキュリティスキャン（Docker 対応）
- PSRule for Azure によるポリシーチェック

**使用方法**:
```bash
./scripts/scan-bicep-security.sh
```

### 3. 詳細ドキュメント

#### SECURITY-SCANNING.md
Bicep ファイルの脆弱性チェックに関する包括的なガイド

**内容**:
- 自動スキャンと手動スキャンの説明
- 各ツールの詳細と使用方法
- よくある脆弱性と対策例
- トラブルシューティング

#### SECURITY-SCAN-EXAMPLES.md
実際の使用例とスキャン結果の解釈方法

**内容**:
- クイックスタートガイド
- スキャン結果の例（成功/警告/エラー）
- よくある問題と対処方法
- CI/CD 統合の例

### 4. README の更新

**変更内容**:
- セキュリティセクションの追加（トップに配置）
- ファイル構成の更新
- ベストプラクティスにセキュリティスキャンを追加
- 関連ドキュメントへのリンク

### 5. .gitignore の追加

**ファイル**: `.gitignore`

不要なファイルをコミットから除外：
- スキャン結果（.sarif ファイル）
- ビルドアーティファクト
- 一時ファイル
- IDE 固有のファイル

## 🎯 使用方法

### 開発者向け（ローカル）

1. **スキャンの実行**:
   ```bash
   ./scripts/scan-bicep-security.sh
   ```

2. **問題の修正**:
   - スキャン結果を確認
   - 脆弱性を修正
   - 再度スキャンして確認

3. **コミット**:
   ```bash
   git add .
   git commit -m "Fix security issues"
   git push
   ```

### GitHub Actions による自動チェック

1. **コードのプッシュ**:
   ```bash
   git push origin main
   ```

2. **結果の確認**:
   - GitHub の「Actions」タブでワークフロー実行状況を確認
   - 「Security」タブで検出された脆弱性を確認

3. **手動実行**:
   - Actions タブ → 「Bicep Security Scan」を選択
   - 「Run workflow」ボタンをクリック

## 📊 スキャンツールの比較

| ツール | 用途 | チェック数 | 特徴 |
|--------|------|-----------|------|
| **Bicep Lint** | 構文・ベストプラクティス | 基本的なチェック | Azure CLI 組み込み |
| **Microsoft Security DevOps** | Azure セキュリティ | 300+ | Azure 公式ツール |
| **Checkov** | IaC セキュリティ | 1000+ | マルチクラウド対応 |
| **PSRule for Azure** | Azure ポリシー | 400+ | Well-Architected 準拠 |

## 🔍 検出される脆弱性の例

- ✅ 暗号化が無効なストレージアカウント
- ✅ 公開アクセスが許可されたリソース
- ✅ 弱い TLS バージョンの使用
- ✅ 不適切なネットワークアクセス制御
- ✅ 監査ログの未設定
- ✅ バックアップの未設定
- ✅ 命名規則の違反

## 📈 今後の改善案

1. **カスタムポリシーの追加**
   - 組織固有のセキュリティルール
   - コンプライアンス要件のチェック

2. **通知の強化**
   - Slack/Teams への通知
   - 重大度別のアラート

3. **定期スキャンの実行**
   - Cron ジョブによる週次スキャン
   - 依存関係の更新チェック

4. **レポートの自動生成**
   - PDF/HTML レポートの作成
   - トレンド分析とダッシュボード

## 🛠️ トラブルシューティング

### ワークフローが実行されない

- ブランチ名が `main` または `develop` であることを確認
- Bicep ファイルに変更があることを確認
- GitHub Actions が有効になっていることを確認

### スキャンがエラーで失敗する

- Azure CLI と Bicep の最新版を使用
  ```bash
  az upgrade
  az bicep upgrade
  ```

### 誤検知（False Positive）への対応

Bicep ファイル内でチェックをスキップ：
```bicep
//checkov:skip=CKV_AZURE_35:Reason for skipping
```

## 📚 参考リンク

- [SECURITY-SCANNING.md](./SECURITY-SCANNING.md) - 詳細ガイド
- [SECURITY-SCAN-EXAMPLES.md](./SECURITY-SCAN-EXAMPLES.md) - 実用例
- [Azure Bicep ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/)
- [Microsoft Security DevOps](https://github.com/microsoft/security-devops-action)
- [Checkov ドキュメント](https://www.checkov.io/)
- [PSRule for Azure](https://azure.github.io/PSRule.Rules.Azure/)

## ✨ まとめ

このリポジトリの Bicep ファイルのセキュリティを自動的にチェックする完全な仕組みが実装されました。

**主な利点**:
- 🔒 セキュリティ脆弱性の早期発見
- 🚀 CI/CD パイプラインへの統合
- 📖 包括的なドキュメント
- 🛠️ ローカル開発環境での利用可能
- 📊 複数のツールによる多角的なチェック

コードをプッシュするだけで、自動的にセキュリティスキャンが実行され、
問題があれば GitHub の Security タブで確認できます。
