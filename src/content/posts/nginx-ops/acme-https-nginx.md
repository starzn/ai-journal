---
title: 使用 acme.sh 给 Nginx 配置 HTTPS 证书
published: 2026-05-10
description: "使用 acme.sh 申请 Let's Encrypt 通配符证书，配置 Nginx HTTPS 并设置自动续期"
tags: [nginx, https, acme.sh, ssl]
category: Nginx 运维
lang: zh_CN
---

## 一、背景

本次目标是为域名：

```text
yyy.com
www.yyy.com
```

配置 HTTPS 访问。

实际申请到的证书包含：

```text
DNS:*.yyy.com
DNS:yyy.com
```

因此该证书支持：

```text
yyy.com
www.yyy.com
blog.yyy.com
api.yyy.com
```

其中：

```text
*.yyy.com
```

表示支持一级子域名，所以 `www.yyy.com` 不需要单独申请证书。

---

## 二、证书申请成功标志

使用 `acme.sh` 申请证书后，如果看到类似：

```text
Cert success.
```

说明证书已经申请成功。

---

## 三、安装证书到 Nginx 目录

虽然 `acme.sh` 会在自己的目录下保存证书，但官方不建议 Nginx 直接引用 `~/.acme.sh/` 目录中的证书文件。

因此需要将证书安装到 Nginx 专用目录。

### 1. 创建证书目录

```bash
mkdir -p /etc/nginx/ssl
```

### 2. 安装证书

```bash
acme.sh --install-cert -d yyy.com \
--key-file /etc/nginx/ssl/yyy.com.key \
--fullchain-file /etc/nginx/ssl/yyy.com.pem \
--reloadcmd "systemctl reload nginx"
```

参数说明：

| 参数 | 说明 |
|---|---|
| `--install-cert` | 安装证书到指定位置 |
| `-d yyy.com` | 指定证书主域名 |
| `--key-file` | 指定私钥保存路径 |
| `--fullchain-file` | 指定完整证书链保存路径 |
| `--reloadcmd` | 证书续期成功后自动执行的命令 |

其中：

```bash
--reloadcmd "systemctl reload nginx"
```

非常重要，表示以后证书自动续期成功后，会自动重载 Nginx，使新证书生效。

---

## 四、查看证书包含的域名

执行：

```bash
openssl x509 -in /etc/nginx/ssl/yyy.com.pem -noout -text | grep -A1 "Subject Alternative Name"
```

本次输出为：

```text
X509v3 Subject Alternative Name:
    DNS:*.yyy.com, DNS:yyy.com
```

说明证书包含：

```text
*.yyy.com
yyy.com
```

因此支持：

```text
yyy.com
www.yyy.com
```

注意：

| 域名 | 是否支持 | 原因 |
|---|---|---|
| `yyy.com` | 支持 | 证书中包含 `DNS:yyy.com` |
| `www.yyy.com` | 支持 | 被 `DNS:*.yyy.com` 覆盖 |
| `blog.yyy.com` | 支持 | 被 `DNS:*.yyy.com` 覆盖 |
| `api.yyy.com` | 支持 | 被 `DNS:*.yyy.com` 覆盖 |
| `a.b.yyy.com` | 不支持 | 通配符只支持一级子域名 |

---

## 五、Nginx 配置 HTTPS

当前网站是静态前端项目，目录为：

```bash
/home/yyy/xxx/dist
```

Nginx 配置如下：

```nginx
server {
    listen 80;
    server_name yyy.com www.yyy.com;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name yyy.com www.yyy.com;

    ssl_certificate /etc/nginx/ssl/yyy.com.pem;
    ssl_certificate_key /etc/nginx/ssl/yyy.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;

    root /home/yyy/xxx/dist;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

配置说明：

| 配置 | 作用 |
|---|---|
| `listen 80` | 监听 HTTP 请求 |
| `return 301 https://$host$request_uri` | 将 HTTP 自动跳转到 HTTPS |
| `listen 443 ssl http2` | 启用 HTTPS 和 HTTP/2 |
| `server_name yyy.com www.yyy.com` | 配置支持的域名 |
| `ssl_certificate` | 指定证书文件 |
| `ssl_certificate_key` | 指定私钥文件 |
| `root` | 指定前端静态文件目录 |
| `try_files $uri $uri/ /index.html` | 支持前端路由刷新不 404 |

---

## 六、检查并重载 Nginx

修改 Nginx 配置后，先检查配置语法：

```bash
nginx -t
```

如果输出类似：

```text
syntax is ok
test is successful
```

说明配置正确。

然后重载 Nginx：

```bash
systemctl reload nginx
```

---

## 七、测试 HTTPS 是否生效

### 1. 测试主域名

```bash
curl -I https://yyy.com
```

正常会返回类似：

```text
HTTP/2 200
```

或：

```text
HTTP/1.1 200 OK
```

### 2. 测试 www 域名

```bash
curl -I https://www.yyy.com
```

如果正常返回响应，说明 `www.yyy.com` 的 HTTPS 也已生效。

### 3. 测试 HTTP 自动跳转 HTTPS

```bash
curl -I http://yyy.com
```

正常应返回：

```text
HTTP/1.1 301 Moved Permanently
Location: https://yyy.com/
```

---

## 八、确认 443 端口是否监听

如果 HTTPS 无法访问，可以检查 Nginx 是否监听 443 端口：

```bash
ss -tunlp | grep nginx
```

正常应看到类似：

```text
LISTEN 0 511 0.0.0.0:443 0.0.0.0:* users:(("nginx",pid=xxx,fd=xxx))
```

---

## 九、云服务器安全组配置

如果使用的是阿里云、腾讯云、华为云等服务器，需要确认安全组入方向放行：

```text
TCP 443
```

如果还需要 HTTP 跳转，也需要放行：

```text
TCP 80
```

---

## 十、防火墙放行 HTTPS

如果服务器开启了 `firewalld`，可以执行：

```bash
firewall-cmd --add-service=https --permanent
firewall-cmd --reload
```

如需同时放行 HTTP：

```bash
firewall-cmd --add-service=http --permanent
firewall-cmd --reload
```

如果系统没有 `firewall-cmd`，说明可能没有启用 `firewalld`，可以根据实际情况处理。

---

## 十一、自动续期配置

`acme.sh` 会通过 crontab 自动检查证书是否需要续期。

查看定时任务：

```bash
crontab -l
```

正常会看到类似：

```bash
9 13 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```

含义是：

```text
每天 13:09 执行一次 acme.sh 自动检查任务
```

注意：

```text
每天检查，不代表每天续期
```

实际逻辑是：

```text
每天 13:09 执行检查
↓
acme.sh 判断证书是否接近续期时间
↓
如果未到续期窗口，则跳过
↓
如果已到续期窗口，则自动续期
↓
续期成功后更新证书文件
↓
执行 systemctl reload nginx
```

---

## 十二、什么时候真正续期？

Let's Encrypt 证书通常有效期约 90 天。
`acme.sh` 会在证书接近到期时自动续期，而不是每天重新申请。
---

## 十三、手动测试续期

如需手动测试续期流程，可以执行：

```bash
acme.sh --renew -d yyy.com --force
```

如果证书是 ECC 证书，则可能需要：

```bash
acme.sh --renew -d yyy.com --ecc --force
```

注意：

```text
不建议频繁强制续期，避免触发 Let's Encrypt 频率限制。
```

---

## 十四、总结

本次 HTTPS 配置完成事项：

- 使用 `acme.sh` 成功申请证书
- 证书包含 `DNS:*.yyy.com` 和 `DNS:yyy.com`
- `www.yyy.com` 已被通配符证书覆盖
- 证书已安装到 `/etc/nginx/ssl/`
- Nginx 已配置 80 跳转 443
- Nginx 已配置 HTTPS 证书
- 已支持前端路由刷新
- 已配置自动续期任务
- 续期成功后会自动执行 `systemctl reload nginx`

后续只需偶尔检查：

```bash
acme.sh --list
```

或：

```bash
openssl x509 -in /etc/nginx/ssl/yyy.com.pem -noout -dates
```
