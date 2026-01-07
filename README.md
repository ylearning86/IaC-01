# Azure Infrastructure as Code - ハンズオン テンプレート

Azure ポータルからエクスポートしたテンプレートを再利用可能な形に改善した Bicep テンプレートです。

## 🔒 セキュリティ

このリポジトリでは、Bicep テンプレートのセキュリティ脆弱性を自動的にスキャンしています。

- ✅ 自動セキュリティスキャン（GitHub Actions）
- ✅ Microsoft Security DevOps
- ✅ Checkov IaC セキュリティチェック
- ✅ PSRule for Azure ポリシー検証

**脆弱性チェック方法の詳細**: [SECURITY-SCANNING.md](./SECURITY-SCANNING.md)

## クイックデプロイ

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fylearning86%2FIaC-01%2Fmain%2Fbicep%2Fmain.json)

### 必須入力パラメータ

Deploy to Azure ボタンを使用する場合、以下のパラメータのみ入力が必要です：

- **vmAdminPassword**: VM管理者パスワード（8文字以上、大文字・小文字・数字・特殊文字を含む）
- **userNumber** (オプション): ユーザー番号（001-050）、デフォルトは `001`

その他のパラメータ（projectName, vmAdminUsername等）はデフォルト値が設定されています。

## 概要

このテンプレートでは以下のリソースをデプロイします：

- **仮想ネットワーク (VNet)** - 2つのサブネットを含む
  - VM サブネット (10.0.1.0/24)
  - Private Endpoint サブネット (10.0.2.0/24)

- **ネットワークセキュリティグループ (NSG)** - 各サブネットに対応
- **仮想マシン (VM)** - Windows Server 2025
- **ストレージアカウント** - StorageV2 with Private Endpoint
- **プライベート DNS ゾーン** - privatelink.blob.core.windows.net
- **プライベートエンドポイント** - ストレージへの安全なアクセス
- **Azure Bastion** - VM への安全なアクセス (オプション)

## ファイル構成

```
IaC-01/
├── README.md
├── SECURITY-SCANNING.md        # セキュリティスキャンガイド
├── .github/
│   └── workflows/
│       └── bicep-security-scan.yml  # 自動セキュリティスキャン
├── scripts/
│   └── scan-bicep-security.sh  # ローカルスキャンスクリプト
└── bicep/
    ├── main.bicep              # メインテンプレート
    ├── main.json               # コンパイル済みARMテンプレート
    ├── parameters.json         # 開発環境用パラメータ
    └── parameters.prod.json    # 本番環境用パラメータ
```

## テンプレートの改善点

ポータルからのエクスポート版と比較して、以下の改善を実施しました：

### 1. **パラメータ化**
- ハードコードされた値をすべてパラメータに外部化
- 環境ごとに異なる値を別ファイルで管理
- デフォルト値を設定して柔軟に対応

### 2. **変数の活用**
- `commonTags` - すべてのリソースに統一的に適用
- `resourceNaming` - リソース名をまとめて管理
- 計算可能な値は変数で定義

### 3. **条件付きデプロイ**
- `enableBastion` - Bastion を含める/除外

### 4. **タグ管理**
- 環境、プロジェクト、コストセンター情報を統一管理
- 作成日時を自動付与 (`utcNow()`)
- 管理ツール情報を記録

### 5. **出力値の定義**
- リソース ID やエンドポイント情報をエクスポート
- 後続の自動化スクリプトで利用可能

### 6. **メタデータとドキュメント**
- リソースの用途と説明をコメントで追加
- セクションごとに分類

## 前提条件

- Azure サブスクリプション
- Azure CLI (最新版)
  ```bash
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash  # Linux
  brew update && brew install azure-cli                     # macOS
  ```
- PowerShell Core (オプション)

## クイックスタート

### 1. Azure にログイン

```bash
az login
```

### 2. リソースグループの作成

```bash
az group create \
  --name rg-handson \
  --location japaneast
```

### 3. ユーザー番号の指定

デプロイ時に `userNumber` パラメータを指定します。例えば、ユーザー番号が `050` の場合：

**CLI で指定する場合:**
```bash
az deployment group create \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json userNumber=050
```

**パラメータファイルを編集する場合:**
```json
"userNumber": {
  "value": "050"
}
```

### 4. テンプレートの検証

```bash
az deployment group validate \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json userNumber=050
```

### 5. テンプレートのデプロイ

**開発環境:**
```bash
az deployment group create \
  --name deployment-handson-dev \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json userNumber=050
```

**本番環境:**
```bash
az deployment group create \
  --name deployment-handson-prod \
  --resource-group rg-handson-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json userNumber=050
```

### 6. PowerShell を使用する場合

```powershell
# ログイン
Connect-AzAccount

# リソースグループ作成
New-AzResourceGroup -Name rg-handson -Location japaneast

# デプロイ
New-AzResourceGroupDeployment `
  -ResourceGroupName rg-handson `
  -TemplateFile main.bicep `
  -TemplateParameterFile parameters.json `
  -userNumber "050"
```

## パラメータのカスタマイズ

### ユーザー番号の指定

`userNumber` パラメータで、各ユーザーに割り当てられた3桁の番号（001-050）を指定します。このパラメータは以下のリソース名に使用されます：

#### リソース名の規則

**固定名のリソース (全ユーザー共通):**
- **仮想ネットワーク**: `vnet-handson`
- **プライベートエンドポイント**: `pe-handson-blob`
- **プライベートエンドポイント NIC**: `pe-handson-blob-nic`
- **サブネット**: `vm-subnet`, `pe-subnet`

**ユーザー番号を含むリソース:**
- **仮想マシン**: `vm-{userNumber}` → `vm-001`, `vm-050`
- **ストレージアカウント**: `sahandson{userNumber}` → `sahandson001`, `sahandson050`
- **ネットワークインターフェース**: `vm-{userNumber}-nic` → `vm-001-nic`, `vm-050-nic`
- **ネットワークセキュリティグループ**: `vm-{userNumber}-nsg` → `vm-001-nsg`, `vm-050-nsg`

#### 命名規則の例 (userNumber=050 の場合)

| リソースタイプ | リソース名 |
|--------------|-----------|
| Virtual Network | `vnet-handson` |
| VM Subnet | `vm-subnet` |
| PE Subnet | `pe-subnet` |
| Virtual Machine | `vm-050` |
| Network Interface | `vm-050-nic` |
| Network Security Group | `vm-050-nsg` |
| Storage Account | `sahandson050` |
| Private Endpoint | `pe-handson-blob` |
| Private Endpoint NIC | `pe-handson-blob-nic` |

**指定方法:**
```bash
# CLI パラメータで指定
az deployment group create \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json userNumber=050
```

### parameters.json を編集する際のポイント

| パラメータ | 説明 | デフォルト値 | 必須 |
|-----------|------|----------|------|
| `vmAdminPassword` | VM 管理者パスワード | なし | ✅ **必須** |
| `userNumber` | ユーザー番号 (3桁、001-050) | `001` | オプション |
| `projectName` | プロジェクト名 | `handson` | オプション |
| `location` | Azure リージョン | リソースグループの場所 | オプション |
| `vmAdminUsername` | VM 管理者ユーザー名 | `azureuser` | オプション |
| `vmSize` | VM のサイズ | `Standard_D2s_v3` | オプション |
| `environment` | 環境名 (dev/prod など) | `dev` | オプション |
| `storageSkuName` | ストレージ SKU | `Standard_RAGRS` | オプション |
| `enableBastion` | Azure Bastion (Developer SKU) をデプロイ | `true` | オプション |

### セキュリティに関する注意

⚠️ **パスワード要件**
- **最小 8 文字以上**
- 大文字、小文字、数字、特殊文字を含む
- 3 回の連続する同一文字を避ける

**推奨方法:**
```bash
# Azure Key Vault でパスワードを管理
az keyvault secret set \
  --vault-name my-keyvault \
  --name vm-admin-password \
  --value "YourSecurePassword123!"

# デプロイ時に参照
az deployment group create \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json \
  --parameters vmAdminPassword=$(az keyvault secret show --vault-name my-keyvault --name vm-admin-password -o tsv --query value)
```

## デプロイ後の確認

### 出力値の取得

```bash
az deployment group show \
  --name deployment-handson-dev \
  --resource-group rg-handson \
  --query properties.outputs
```

出力例：
```json
{
  "vnetId": {
    "type": "String",
    "value": "/subscriptions/xxx/resourceGroups/rg-handson/providers/Microsoft.Network/virtualNetworks/handson-vnet"
  },
  "vmId": {
    "type": "String",
    "value": "/subscriptions/xxx/resourceGroups/rg-handson/providers/Microsoft.Compute/virtualMachines/handson-vm"
  },
  "storageAccountName": {
    "type": "String",
    "value": "hansonstxxxxx"
  }
}
```

### リソースの確認

```bash
# リソースグループ内のリソース一覧
az resource list --resource-group rg-handson -o table

# VM の詳細情報
az vm show --resource-group rg-handson --name handson-vm

# ストレージアカウント情報
az storage account show --resource-group rg-handson --name <storage-name>
```

## Azure Bastion を使用した VM へのアクセス

Azure Bastion (Developer SKU) を有効にしている場合：

1. Azure ポータルで VM リソースを開く
2. 「接続」 → 「Bastion」 を選択
3. ユーザー名とパスワードで接続

RDP でアクセスする場合：

```bash
# RDP ファイル取得 (Windows VM の場合)
az vm open-port --resource-group rg-handson --name handson-vm --port 3389
```

## トラブルシューティング

### デプロイが失敗する場合

**エラー: "リソースが既に存在します"**
```bash
# 別の名前でデプロイ
parameters.json の projectName を変更
```

**エラー: "リージョンでリソースが利用不可"**
```bash
# 別のリージョンを選択
parameters.json の location を変更（例：eastus, westeurope）
```

**エラー: "パスワード検証エラー"**
```bash
# 要件を満たすパスワードに変更
# - 8 文字以上
# - 大文字・小文字・数字・特殊文字を含む
```

## リソースの削除

リソースが不要になった場合：

```bash
# リソースグループ全体を削除
az group delete --name rg-handson --yes --no-wait
```

## ベストプラクティス

### セキュリティスキャン

デプロイ前にセキュリティ脆弱性をチェック：

```bash
# ローカルでセキュリティスキャンを実行
./scripts/scan-bicep-security.sh

# または個別に Bicep Lint を実行
az bicep build --file bicep/main.bicep
```

**詳細なガイド**: [SECURITY-SCANNING.md](./SECURITY-SCANNING.md) を参照してください。

GitHub にプッシュすると自動的にセキュリティスキャンが実行され、結果は Security タブで確認できます。

### テンプレートの検証

デプロイ前に必ず検証を実施：

```bash
az deployment group validate \
  --resource-group rg-handson \
  --template-file main.bicep \
  --parameters parameters.json

# または詳細な検証
bicep build main.bicep
```

### パラメータの別ファイル化

環境ごとに異なる設定値は `parameters.{env}.json` で管理：

```bash
# dev
az deployment group create \
  --resource-group rg-handson-dev \
  --template-file main.bicep \
  --parameters parameters.json

# staging
az deployment group create \
  --resource-group rg-handson-staging \
  --template-file main.bicep \
  --parameters parameters.staging.json

# prod
az deployment group create \
  --resource-group rg-handson-prod \
  --template-file main.bicep \
  --parameters parameters.prod.json
```

### CI/CD 統合

GitHub Actions での使用例：

```yaml
name: Deploy IaC

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Validate Template
        run: |
          az deployment group validate \
            --resource-group rg-handson \
            --template-file main.bicep \
            --parameters parameters.json
      
      - name: Deploy Template
        run: |
          az deployment group create \
            --resource-group rg-handson \
            --template-file main.bicep \
            --parameters parameters.json
```

## 次のステップ

- [Bicep 公式ドキュメント](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/)
- [Azure テンプレート スペック](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/templates/template-specs)
- [Azure Blueprints](https://learn.microsoft.com/ja-jp/azure/governance/blueprints/)

## ライセンス

このテンプレートは自由に使用・編集できます。

## GitHub公開とDeploy to Azureボタンの設定

### 1. GitHubリポジトリの準備

```bash
# Gitリポジトリの初期化（まだの場合）
git init
git add .
git commit -m "Initial commit: Azure IaC template"

# GitHubリポジトリと接続
git remote add origin https://github.com/[YOUR-USERNAME]/[YOUR-REPO].git
git branch -M main
git push -u origin main
```

### 2. Deploy to Azureボタンの更新

README.md の最初にあるDeploy to Azureボタンのリンクを編集：

```markdown
[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2F[YOUR-USERNAME]%2F[YOUR-REPO]%2Fmain%2Fmain.json)
```

`[YOUR-USERNAME]` と `[YOUR-REPO]` を実際の値に置き換えてください。

### 3. 使用方法

1. GitHubリポジトリのREADMEで「Deploy to Azure」ボタンをクリック
2. Azureポータルが開きます
3. 以下の項目を入力：
   - **Subscription**: Azureサブスクリプションを選択
   - **Resource Group**: 新規作成または既存を選択
   - **Region**: デプロイ先のリージョンを選択
   - **Vm Admin Password**: VM管理者パスワード（**必須**）
   - **User Number**: ユーザー番号（デフォルト: 001）
4. 「Review + create」→「Create」でデプロイ開始

### 4. main.jsonの更新

Bicepファイルを変更した場合は、必ずmain.jsonを再生成してコミット：

```bash
az bicep build --file main.bicep
git add main.json
git commit -m "Update ARM template"
git push
```

## サポート

問題が発生した場合：

1. Azure CLI のバージョンを確認
   ```bash
   az --version
   ```

2. Bicep ファイルを検証
   ```bash
   bicep build main.bicep
   ```

3. Azure ドキュメントを参照
   - [Azure CLI - az deployment group](https://learn.microsoft.com/ja-jp/cli/azure/deployment/group)
   - [Bicep リファレンス](https://learn.microsoft.com/ja-jp/azure/azure-resource-manager/bicep/file)
