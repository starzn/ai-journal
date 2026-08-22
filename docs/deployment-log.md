# 生产部署日志

## 2026-08-22：服务器镜像历史保留

- 健康检查通过后更新 `RELEASE_HISTORY`，固定保留当前版本和最近 2 个成功发布的历史版本。
- 只删除 AI Journal 自己的完整 Git SHA 镜像，不触碰其他项目、基础镜像或非发布标签。
- 首次启用时保留当前版本 `8e2a0192ef9f25a1e46e61676f234cfe65f0d34b` 与现有历史版本 `d083af24468146b1bf4a0f7fe0814a8b0d55b620`；当前没有更旧镜像需要删除。

## 2026-08-22：GitHub Actions SSH 最小权限加固

- 工作流提交：`fd3263e`
- 幂等部署版本：`8e2a0192ef9f25a1e46e61676f234cfe65f0d34b`
- GitHub Actions run：[`32553558287`](https://github.com/starzn/ai-journal/actions/runs/32553558287)
- AI Journal 保留独立 Ed25519 Key；ECS 公钥增加 OpenSSH `restrict` 和强制命令，只接受 `deploy-ai-journal <40位SHA>`。
- Actions 新增固定的 ECS Ed25519 Host Key，不在 Runner 中动态信任服务器。
- 工作流先执行普通 `id` 命令并确认被拒绝，再调用受限部署命令。
- 幂等镜像部署、容器健康和 `https://starzn.xyz/` 公网 TLS 检查全部通过，运行耗时 14 秒。

## 2026-08-22：首次不可变镜像部署

- 站点：`https://starzn.xyz/`
- Git commit：`8e2a0192ef9f25a1e46e61676f234cfe65f0d34b`
- 生产镜像：`starzn_deploy/ai-journal-web:8e2a0192ef9f25a1e46e61676f234cfe65f0d34b`
- GitHub Actions run：[`32546384029`](https://github.com/starzn/ai-journal/actions/runs/32546384029)
- 架构：`linux/amd64`
- 发布链路：Mac buildx → 阿里云 ACR 公网地址 → deploy tag → GitHub Actions SSH → ECS ACR VPC 地址

部署契约：

- ECS 不执行依赖安装、站点构建或 Docker build。
- 应用容器不暴露宿主机端口，仅通过外部 Docker 网络
  `starzn_internal` 的 `ai-journal-web:8080` 提供给共享 Nginx。
- 容器以 UID/GID `101:101`、只读根文件系统运行，限制为 64 MiB、0.25 CPU。
- 镜像以完整 Git SHA 标记；部署失败时恢复 `PREVIOUS_IMAGE`。
- 服务器完成容器健康检查与本机 TLS 路由检查，GitHub runner 完成公网 TLS 检查。

验收结果：

- GitHub Actions 部署任务成功。
- ECS 容器状态为 `healthy`，运行镜像与上述 Git SHA 一致。
- `https://starzn.xyz/` 返回 HTTP 200。
- 公网证书链验证结果为 `Verify return code: 0 (ok)`。

同日将 acme.sh 从 root 迁移到 deploy：

- ACME 账号、DNS 验证与每日续期检查均由 deploy 管理。
- 正式证书安装到 `/home/deploy/certs/starzn.xyz`。
- 续期后先验证有效期、完整链、私钥匹配和域名，再热重载共享 Nginx。
- root 的 acme.sh、证书目录和续期 cron 已删除。
