#!/bin/bash
# Bicep ファイルのセキュリティスキャンスクリプト
# このスクリプトはローカル環境でBicepファイルの脆弱性をチェックします

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BICEP_DIR="$PROJECT_DIR/bicep"

echo "🔒 Bicep セキュリティスキャンを開始します..."
echo "プロジェクトディレクトリ: $PROJECT_DIR"
echo "Bicep ディレクトリ: $BICEP_DIR"
echo ""

# 1. Bicep Lint チェック
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  Bicep Lint チェック"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v az &> /dev/null; then
    echo "✅ Azure CLI が見つかりました"
    
    for file in "$BICEP_DIR"/*.bicep; do
        if [ -f "$file" ]; then
            echo ""
            echo "📄 チェック中: $(basename "$file")"
            if az bicep build --file "$file" --stdout > /dev/null 2>&1; then
                echo "  ✅ 構文チェック: 問題なし"
            else
                echo "  ❌ 構文チェック: エラーが見つかりました"
                az bicep build --file "$file" 2>&1 | grep -E "Warning|Error" || true
            fi
        fi
    done
else
    echo "⚠️  Azure CLI が見つかりません。スキップします。"
    echo "   インストール: https://learn.microsoft.com/ja-jp/cli/azure/install-azure-cli"
fi

# 2. Checkov スキャン
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  Checkov IaC セキュリティスキャン"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v checkov &> /dev/null; then
    echo "✅ Checkov が見つかりました"
    echo ""
    checkov -d "$BICEP_DIR" --framework bicep --compact --quiet
elif command -v docker &> /dev/null; then
    echo "📦 Docker を使用して Checkov を実行します..."
    docker run --rm -v "$PROJECT_DIR:/tf" bridgecrew/checkov -d /tf/bicep --framework bicep --compact --quiet
else
    echo "⚠️  Checkov が見つかりません。スキップします。"
    echo "   インストール: pip install checkov"
    echo "   または Docker: docker pull bridgecrew/checkov"
fi

# 3. PSRule for Azure
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  PSRule for Azure ポリシーチェック"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if command -v pwsh &> /dev/null; then
    echo "✅ PowerShell が見つかりました"
    
    # PSRule.Rules.Azure モジュールがインストールされているか確認
    if pwsh -Command "Get-Module -ListAvailable -Name PSRule.Rules.Azure" &> /dev/null; then
        echo "✅ PSRule.Rules.Azure モジュールが見つかりました"
        echo ""
        
        # ARM テンプレートにビルド
        for file in "$BICEP_DIR"/*.bicep; do
            if [ -f "$file" ]; then
                az bicep build --file "$file" 2>/dev/null || true
            fi
        done
        
        # PSRule 実行
        pwsh -Command "Assert-PSRule -Module PSRule.Rules.Azure -InputPath '$BICEP_DIR' -Format File -OutputFormat Console" || true
    else
        echo "⚠️  PSRule.Rules.Azure モジュールが見つかりません"
        echo "   インストール: Install-Module -Name PSRule.Rules.Azure -Scope CurrentUser"
    fi
else
    echo "⚠️  PowerShell が見つかりません。スキップします。"
    echo "   インストール: https://learn.microsoft.com/ja-jp/powershell/scripting/install/installing-powershell"
fi

# まとめ
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ スキャン完了"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 推奨事項:"
echo "  1. 見つかった警告とエラーを確認してください"
echo "  2. セキュリティのベストプラクティスに従ってください"
echo "  3. GitHub にプッシュすると自動的にスキャンが実行されます"
echo ""
