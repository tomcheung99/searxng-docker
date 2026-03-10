# Railway Deployment Guide

本指南說明如何在 [Railway](https://railway.app) 上以 **Dockerfile** 模式部署 SearXNG。

---

## 為什麼不直接用 `docker-compose.yaml`？

目前的 `docker-compose.yaml` 有幾個地方在 Railway PaaS 上無法運作：

| 問題 | 原因 |
|------|------|
| `caddy: network_mode: host` | Railway 不允許容器使用 host 網路 |
| `ports: "127.0.0.1:8080:8080"` | 只綁 localhost，Railway 的路由器無法連到容器 |
| Caddy 自動申請 Let's Encrypt | Railway 本身已提供網域和 HTTPS，不需要 Caddy |

因此建議在 Railway 上使用 **Dockerfile 部署**（本 repo 根目錄已提供 `Dockerfile`），並把 Redis 改用 Railway 的 Redis 服務。

---

## 部署步驟

### 1. 建立 Railway 專案

1. 登入 [Railway Dashboard](https://railway.app/dashboard)
2. 點選 **New Project** → **Deploy from GitHub repo**
3. 選擇 `tomcheung99/searxng-docker`（或你 fork 的版本）

### 2. 確認 Railway 使用 Dockerfile 部署

Railway 偵測到根目錄有 `Dockerfile` 後，會自動使用 Docker build 模式（不再走 Railpack/Nixpacks）。  
如果仍顯示 Railpack，請至服務設定 → **Builder** → 選擇 **Dockerfile**。

### 3. 新增 Redis 服務

SearXNG 需要 Redis 做 limiter/快取：

1. 在同一個 Railway 專案中，點選 **+ New** → **Database** → **Add Redis**
2. Redis 服務建好後，Railway 會自動提供幾個環境變數，包括 `REDIS_URL`（格式：`redis://:password@host:port`）

### 4. 更新 `searxng/settings.yml` 中的 Redis 連線

預設的 `searxng/settings.yml` 使用 docker-compose 的 Redis hostname：

```yaml
redis:
  url: redis://redis:6379/0
```

部署到 Railway 時，請將上方的 URL 改成 Railway Redis 服務提供的連線字串，例如：

```yaml
redis:
  url: redis://:your_password@containers-us-west-xxx.railway.app:6379/0
```

> **建議做法**：使用環境變數取代硬編碼，避免把密碼寫進版本控制。  
> 你可以在 `settings.yml` 中使用 `${REDIS_URL}` 佔位符（SearXNG 支援從環境變數讀取 `SEARXNG_REDIS_URL`），或在 Railway 的 SearXNG 服務設定頁面，把 Railway Redis 服務的 `REDIS_URL` 變數用 **Reference Variable** 的方式注入。
>
> 最簡單的方法：在 Railway SearXNG 服務的 **Variables** 頁面新增：
> ```
> SEARXNG_REDIS_URL=${{Redis.REDIS_URL}}
> ```
> （`Redis` 為你在 Railway 建立的 Redis 服務名稱）

### 5. 設定必要環境變數

在 Railway SearXNG 服務的 **Variables** 頁面，至少設定以下變數：

| 變數名稱 | 範例值 | 說明 |
|----------|--------|------|
| `SEARXNG_BASE_URL` | `https://your-app.up.railway.app/` | 對外網址（結尾需有 `/`），從 Railway 的 Settings → Domains 取得 |
| `SEARXNG_SECRET_KEY` | `（用 openssl rand -hex 32 產生）` | 必須更換，不可使用預設值 |
| `SEARXNG_REDIS_URL` | `${{Redis.REDIS_URL}}` | 參考上方 Redis 步驟 |

> **注意**：`SEARXNG_BASE_URL` 必須是 `https://` 開頭的完整 URL 並以 `/` 結尾，否則 SearXNG 的 CSRF 保護可能會擋掉請求。

### 6. 部署並開啟網域

1. Railway 會自動觸發 build，使用根目錄的 `Dockerfile`
2. Build 完成後，前往服務的 **Settings → Networking → Generate Domain**，取得公開網址
3. 將該網址填入 `SEARXNG_BASE_URL` 環境變數（若尚未設定）

---

## 本機 docker-compose 部署不受影響

新增的 `Dockerfile` 和 `start.sh` 不會影響本機的 docker-compose 部署。  
本機仍可照原本的 [README.md](README.md) 步驟，用 `docker compose up -d` 啟動完整 stack（SearXNG + Redis/Valkey + Caddy）。

---

## 常見問題

### Railway build 仍顯示 Railpack 錯誤？

- 確認根目錄存在 `Dockerfile`（已提交到版本庫）
- 至 Railway 服務設定 → **Builder** 手動切換為 **Dockerfile**

### 容器啟動後無法連線？

- 確認 `SEARXNG_BASE_URL` 已設定為正確的 Railway 網域（`https://...`）
- 確認 Railway 服務的 **Networking** 有開啟 public domain
- 查看 Railway Deploy Logs 確認 `BIND_ADDRESS` 已設為 `0.0.0.0:PORT`

### CSRF / 403 錯誤？

- `SEARXNG_BASE_URL` 必須與瀏覽器存取的 URL 完全一致（包含 `https://` 和結尾 `/`）

### Redis 連線失敗？

- 確認 `SEARXNG_REDIS_URL` 環境變數已正確設定為 Railway Redis 的連線字串
- 在 `searxng/settings.yml` 中確認 `redis.url` 使用的是環境變數或正確的 Redis 地址
