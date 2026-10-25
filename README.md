# 在线书库 · books.mars-y.com

自托管在线电子书阅读站点，部署于 Cloudflare Pages，含书架 / 阅读器 / 全网搜书（Z-Library）三部分。

## 访问入口

| 页面 | URL |
|---|---|
| 书架 | `https://books.mars-y.com/` |
| 阅读器（指定书） | `https://books.mars-y.com/reader?file=books/<文件名>&title=<书名>` |
| 全网搜书 | `https://books.mars-y.com/search` |
| Koodo Reader | `https://books.mars-y.com/koodo/` |
| 示例 | `https://books.mars-y.com/reader?file=books/Contagious_Jonah_Berger.epub&title=Contagious（疯传）` |

> 说明：Cloudflare Pages 自动把 `/reader` → `reader.html`、`/search` → `search.html`（无需 `_redirects`；加 `_redirects` 反而会产生 308 循环，已移除）。

## 目录结构（站点根：本目录）

```
index.html      书架（书库网格 + 书架内搜索 + 全网搜书入口）
reader.html     阅读器（epub.js + pdf.js；支持 ?file=&title= 参数）
search.html     全网搜书（Z-Library 检索 + opencode 下载入架流程说明）
lib/            epub.min.js / jszip.min.js / pdf.min.js / pdf.worker.min.js
books/          电子书（EPUB/PDF），EPUB 支持在线阅读
deploy.sh       一键部署到 Cloudflare Pages
```

## 阅读器参数

- `file`：书籍在 `books/` 下的相对路径，如 `books/Contagious_Jonah_Berger.epub`
- `title`：顶部显示的书名（中文可直接用，浏览器自动编码）

EPUB 用 epub.js（翻页 + 目录），PDF 用 pdf.js（逐页渲染）。

## 全网搜书（搜书 → 入架工作流）

书源：Z-Library（个人学习备份）。检索与下载由 **opencode 书搜 agent** 完成。

### opencode 书搜 agent

- agent 文件：`~/.config/opencode/agents/book-search.md`
- 搜书脚本：`/home/user/.doubao/agent_mode/workspace/tools/book-search/book-search.js`

用法（在 terminal）：
```bash
# 启动 mihomo 代理（节点轮换/反爬所需）
cd /home/user/.doubao/agent_mode/workspace/tools/mihomo && ./mihomo -d . -f config.yaml &

# 搜书名（看结果）
opencode run book-search "Contagious Jonah Berger"

# 搜+下载第一个 EPUB 到 books/，再部署
opencode run book-search "The Psychology of Money" --out /home/user/Doubao/chats/38448472986223874/books
```

脚本直接调用（更快）：
```bash
S=/home/user/.doubao/agent_mode/workspace/tools/book-search/book-search.js
node $S search "书名 作者" --proxy http://127.0.0.1:7890
node $S fetch  "书名 作者" --out <站点>/books --name 书名.epub --proxy http://127.0.0.1:7890 --rotate
```

### 脚本能力

- 自动解 Z-Library 的 SHA1 PoW（c_token cookie）
- 跟随镜像 301 重定向到可用域名
- 下载按文件魔数识别真实格式（EPUB=504b0304 / PDF=25504446 / MOBI=CR!Z）
- 匿名每日 5 次/IP 限额：`--rotate` 自动经 mihomo API(9090) 切 PROXY 组节点换 IP 重试
- 下载受限书自动回详情页取 `addDownloadedBook` 真实短链

### 添加新书入架

1. 下载到 `books/`（epub 优先）。
2. 在 `index.html` 的 `BOOKS` 数组加一条：`{f:"文件名",t:"书名",a:"作者",fmt:"EPUB",tag:"分类",c1:"#色",c2:"#色"}`。
3. 运行 `bash deploy.sh` 重新部署。
4. 新书出现在书架，点开即读。

## 部署

```bash
bash deploy.sh        # 部署整个站点（含 books/、lib/）
```

底层命令：
```bash
CLOUDFLARE_API_TOKEN=<token> CLOUDFLARE_ACCOUNT_ID=<account> \
  wrangler pages deploy . --project-name books --branch main
```
（项目：`books`，自定义域名 `books.mars-y.com`）

## Koodo Reader（已部署）

Koodo Reader（github.com/koodo-reader/koodo-reader）的 web 版已上线，入口 `https://books.mars-y.com/koodo/`，提供更强的书架/注释/OPDS 能力。

**构建方式**：沙箱 npm/yarn 直连下载部分包被 CDN 层污染（react-scripts/cross-spawn/register-scheme 反复损坏），故改用官方 ghcr.io 镜像提取预构建静态包：
```
# 用 gh 的 token 认证 ghcr，拉 ghcr.io/koodo-reader/koodo-reader:master 的 amd64 manifest，
# 下载 layers（blob 需 -L 跟随 302），解包合并后取 /usr/share/caddy（即 web build），
# 复制到站点根目录 koodo/ 下即可。当前提取产物在 tools/koodo-web/koodo-build/。
```

说明：Koodo Reader 不支持 `?file=` 参数直接打开指定书，因此 `books.mars-y.com/reader?file=...` 仍由当前 epub.js 阅读器承担（即指定 URL 不受影响）；Koodo 内的书需在其界面导入到浏览器书库。

## 运维备注

- 代理：mihomo（`/home/user/.doubao/agent_mode/workspace/tools/mihomo`），节点切换/出口验证见 `network-ops.md`。
- Cloudflare 凭据：`/home/user/.doubao/agent_mode/workspace/tools/credentials.md`。
