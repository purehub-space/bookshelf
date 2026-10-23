#!/usr/bin/env bash
# 部署 books 站点到 Cloudflare Pages（books.mars-y.com）
# 用法: bash deploy.sh [--no-koodo]   不加参数会把 koodo/ 一起部署（若存在）
set -euo pipefail
D="/home/user/Doubao/chats/38448472986223874"
# 从本地凭据档案读取（不入库），避免 secret 推送到 GitHub 被 push-protection 拦截
CRED="/home/user/.doubao/agent_mode/workspace/tools/credentials.md"
if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  export CLOUDFLARE_API_TOKEN="$(grep -oE 'cfat_[A-Za-z0-9]+' "$CRED" | head -1)"
fi
if [[ -z "${CLOUDFLARE_ACCOUNT_ID:-}" ]]; then
  export CLOUDFLARE_ACCOUNT_ID="$(grep -oE 'cd8a[0-9a-f]+' "$CRED" | head -1)"
fi

cd "$D"
echo ">>> 部署到 Cloudflare Pages (books)…"
if [[ "${1:-}" == "--no-koodo" && -d koodo ]]; then
  wrangler pages deploy . --project-name books --branch main --exclude=koodo 2>&1 | tail -15
else
  wrangler pages deploy . --project-name books --branch main 2>&1 | tail -15
fi
