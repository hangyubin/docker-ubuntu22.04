## Ubuntu Systemd LXC 镜像构建工具

一键构建内置 systemd 和 SSH 的 Ubuntu LXC 容器镜像。

### 快速开始

```bash
# 1. 下载脚本
wget https://你的地址/build-lxc.sh
chmod +x build-lxc.sh

# 2. 运行构建（需要 root 权限）
sudo ./build-lxc.sh

# 3. 获取镜像
ls ubuntu-22.04-systemd.tar.gz
```

### 配置选项

编辑脚本开头的配置项：

```bash
UBUNTU_VERSION="22.04"      # 版本: 22.04, 20.04, 24.04
ROOT_PASSWORD="123456"      # root 密码
SSH_PORT="22"               # SSH 端口
INSTALL_PACKAGES=""         # 额外软件包，如 "vim curl"
```

### 构建不同配置的镜像

```bash
# 最小化镜像（默认）
./build-lxc.sh

# 带工具的开发镜像（修改脚本）
INSTALL_PACKAGES="vim curl net-tools htop"

# Ubuntu 20.04 镜像
UBUNTU_VERSION="20.04"
```

### 输出文件

| 文件 | 说明 |
|------|------|
| `ubuntu-22.04-systemd.tar.gz` | Ubuntu 22.04 LXC 模板 |
| `ubuntu-20.04-systemd.tar.gz` | Ubuntu 20.04 LXC 模板 |
| `ubuntu-24.04-systemd.tar.gz` | Ubuntu 24.04 LXC 模板 |

### 导入 Proxmox VE

```bash
# 上传模板
scp ubuntu-22.04-systemd.tar.gz root@你的PVE:/var/lib/vz/template/cache/

# 创建容器
pct create 100 local:vztmpl/ubuntu-22.04-systemd.tar.gz \
    --rootfs local-lvm:8 \
    --memory 1024 \
    --cores 2 \
    --net0 name=eth0,bridge=vmbr0,ip=dhcp \
    --unprivileged 0

# 启动
pct start 100

# 进入
pct enter 100
```

### 导入传统 LXC

```bash
# 解压到容器目录
tar -xf ubuntu-22.04-systemd.tar.gz -C /var/lib/lxc/新容器名/rootfs

# 创建配置文件
cat > /var/lib/lxc/新容器名/config << 'EOF'
lxc.rootfs.path = dir:/var/lib/lxc/新容器名/rootfs
lxc.uts.name = 新容器名
lxc.arch = amd64
lxc.net.0.type = veth
lxc.net.0.link = lxcbr0
lxc.net.0.flags = up
lxc.mount.auto = proc:rw sys:rw
EOF

# 启动
lxc-start -n 新容器名 -d
lxc-attach -n 新容器名
```

### 常用命令

| 操作 | 命令 |
|------|------|
| 构建镜像 | `sudo ./build-lxc.sh` |
| 查看镜像 | `ls -lh *.tar.gz` |
| 测试镜像 | `tar -tzf ubuntu-22.04-systemd.tar.gz \| head -20` |
| 清理临时文件 | `rm -rf ./ubuntu-*-rootfs` |

### 登录信息

- **用户名**: root
- **密码**: 你设置的密码（默认 123456）
- **SSH 端口**: 你设置的端口（默认 22）

### 常见问题

**Q: 构建失败，提示 debootstrap 未安装？**
```bash
apt update && apt install -y debootstrap
```

**Q: 需要 root 权限？**
```bash
sudo ./build-lxc.sh
```

**Q: 如何修改默认配置？**
直接编辑脚本开头的变量即可。

**Q: 镜像太大？**
减少 `INSTALL_PACKAGES` 中的软件包。

**Q: 支持 ARM 架构？**
修改脚本中的 `ARCH="arm64"`

### 依赖要求

| 依赖 | 说明 |
|------|------|
| debootstrap | 构建 rootfs |
| tar | 打包 |
| root 权限 | 必须 |

### 许可证

MIT
