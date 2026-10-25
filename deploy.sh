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

# 站点目录内含工具临时目录 .tmp-tool-results/（其中 .fuse* 是工具虚拟文件系统占位，
# 无法删除且会让 wrangler 遍历时报 "A file or directory could not be found"）。
# 因此复制到干净的临时暂存目录再部署，排除 .git/.wrangler/.tmp-tool-results 等。
STAGE="$(mktemp -d)/books-staging"
mkdir -p "$STAGE"
echo ">>> 复制到暂存目录 $STAGE"
for item in index.html reader.html search.html lib books koodo; do
  [[ -e "$D/$item" ]] && cp -r "$D/$item" "$STAGE/"
done

cd "$STAGE"
echo ">>> 部署到 Cloudflare Pages (books)…"
if [[ "${1:-}" == "--no-koodo" ]]; then
  rm -rf "$STAGE/koodo"
fi
wrangler pages deploy . --project-name books --branch main --commit-dirty=true 2>&1 | tail -15
rc=$?
rm -rf "$STAGE"
exit $rc
