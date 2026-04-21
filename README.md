
# Ubuntu 22.04 Systemd Docker Container

基于 Ubuntu 22.04 的 Docker 镜像，内置 systemd 和 dbus，支持在容器内使用 `systemctl` 命令。

## 功能特性

- ✅ Ubuntu 22.04 LTS 基础镜像
- ✅ 阿里云国内源加速（可修改）
- ✅ systemd 作为 PID 1 运行
- ✅ 支持 `systemctl` 命令
- ✅ 优化 cgroup v2 兼容性
- ✅ 屏蔽不必要的 systemd 服务，减少启动错误
- 🔧 可选 SSH 服务（默认注释）

## 前置要求

### 宿主机要求

| 项目 | 要求 |
|------|------|
| Docker 版本 | 20.10+ |
| 特权模式 | 必须支持 `--privileged` |
| Cgroup | 支持 cgroup v2（推荐）或 v1 |

### OpenWrt 用户注意事项

如果在 OpenWrt 上运行，需要确保 cgroup v2 已挂载：

```bash
mount | grep cgroup2
```

如果未挂载，执行：

```bash
mount -t cgroup2 cgroup2 /sys/fs/cgroup
```

## 快速开始

### 1. 构建镜像

```bash
docker build -t ubuntu-systemd -f ubuntu.dockerfile .
```

### 2. 运行容器

```bash
docker run -d \
  --name ubuntu-dev \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  ubuntu-systemd
```

### 3. 进入容器

```bash
docker exec -it ubuntu-dev /bin/bash
```

### 4. 测试 systemctl

```bash
systemctl status
systemctl --version
```

## 启用 SSH

如果需要 SSH 远程访问，取消 Dockerfile 中的注释：

```dockerfile
RUN apt-get update && \
    apt-get install -y openssh-server && \
    ssh-keygen -A && \
    echo "root:123456" | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```

重新构建并运行：

```bash
# 构建
docker build -t ubuntu-systemd-ssh -f ubuntu.dockerfile .

# 运行（映射端口 2222 -> 22）
docker run -d \
  --name ubuntu-ssh \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 2222:22 \
  ubuntu-systemd-ssh

# SSH 连接
ssh root@localhost -p 2222
# 密码: 123456
```

## 常用命令

| 操作 | 命令 |
|------|------|
| 查看容器状态 | `docker ps` |
| 停止容器 | `docker stop ubuntu-dev` |
| 启动容器 | `docker start ubuntu-dev` |
| 重启容器 | `docker restart ubuntu-dev` |
| 进入容器 | `docker exec -it ubuntu-dev /bin/bash` |
| 查看日志 | `docker logs ubuntu-dev` |
| 删除容器 | `docker rm -f ubuntu-dev` |

## 镜像保存与迁移

### 提交为镜像

```bash
docker commit ubuntu-dev my-ubuntu:latest
```

### 导出为 tar 文件

```bash
# 导出容器
docker export ubuntu-dev > ubuntu-dev.tar

# 导出镜像
docker save ubuntu-systemd:latest | gzip > ubuntu-systemd.tar.gz
```

### 导入 tar 文件

```bash
# 导入容器 tar
docker import ubuntu-dev.tar ubuntu-imported:latest

# 导入镜像 tar
docker load < ubuntu-systemd.tar.gz
```

## 常见问题

### Q: systemctl 报错 "Failed to get D-Bus connection"

**原因**：容器未以特权模式运行或 cgroup 未挂载

**解决**：
```bash
docker run -d --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:rw ...
```

### Q: CentOS 7 容器在 OpenWrt 上 systemctl 无法使用

**原因**：CentOS 7 的 systemd 版本过旧，不支持 cgroup v2

**解决**：使用本 Ubuntu 22.04 镜像

### Q: 容器内防火墙无法启动

**说明**：Docker 容器不需要防火墙，使用 `-p` 端口映射即可

### Q: 如何安装其他软件

进入容器后执行：
```bash
apt update && apt install -y 软件名
```

## 目录结构

```
.
├── ubuntu.dockerfile    # Dockerfile 文件
├── README.md            # 使用说明
└── build.sh             # 构建脚本（可选）
```

## 构建脚本示例

创建 `build.sh`：

```bash
#!/bin/bash

# 构建镜像
docker build -t ubuntu-systemd -f ubuntu.dockerfile .

# 运行容器
docker run -d \
  --name ubuntu-dev \
  --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  ubuntu-systemd

echo "容器已启动，执行以下命令进入："
echo "docker exec -it ubuntu-dev /bin/bash"
```

## 许可证

MIT

## 参考链接

- [Ubuntu 22.04 官方镜像](https://hub.docker.com/_/ubuntu)
- [Docker systemd 最佳实践](https://systemd.io/CONTAINER_INTERFACE/)

---

这份说明包含了构建、运行、SSH 配置、常见问题等完整内容，适合上传至 GitHub。需要调整格式或补充内容吗？
