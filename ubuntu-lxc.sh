#!/bin/bash
# 保存为 build-lxc.sh

set -e

# ========== 可调整配置（按需修改） ==========
UBUNTU_VERSION="22.04"      # 版本: 22.04, 20.04, 24.04
ROOT_PASSWORD="123456"      # root 密码
SSH_PORT="22"               # SSH 端口
INSTALL_PACKAGES=""         # 额外软件包，用空格分开，如 "vim curl net-tools"
# ==========================================

# 版本映射
case $UBUNTU_VERSION in
    20.04) CODENAME="focal" ;;
    22.04) CODENAME="jammy" ;;
    24.04) CODENAME="noble" ;;
esac

ROOTFS_DIR="./ubuntu-${CODENAME}-rootfs"
OUTPUT_TAR="./ubuntu-${CODENAME}-systemd.tar.gz"

echo "=== 构建 Ubuntu ${UBUNTU_VERSION} systemd rootfs ==="

# 安装 debootstrap
command -v debootstrap &> /dev/null || apt update && apt install -y debootstrap

# 创建 rootfs
debootstrap --arch=amd64 ${CODENAME} ${ROOTFS_DIR} http://mirrors.aliyun.com/ubuntu/

# 配置
cat > ${ROOTFS_DIR}/setup.sh << EOF
#!/bin/bash
set -e

# 换源
sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装必要软件
apt update
apt install -y systemd dbus openssh-server ${INSTALL_PACKAGES}
apt clean

# 配置 SSH
ssh-keygen -A
echo "root:${ROOT_PASSWORD}" | chpasswd
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/#Port 22/Port ${SSH_PORT}/' /etc/ssh/sshd_config

# 屏蔽不必要服务
systemctl mask dev-mqueue.mount sys-kernel-config.mount \
    sys-kernel-debug.mount display-manager.service graphical.target

# 清理
rm -f /etc/machine-id /etc/ssh/ssh_host_*
rm -rf /tmp/* /var/log/*.log
EOF

chmod +x ${ROOTFS_DIR}/setup.sh

# 执行配置
mount --bind /dev ${ROOTFS_DIR}/dev
mount --bind /proc ${ROOTFS_DIR}/proc
chroot ${ROOTFS_DIR} /setup.sh
umount ${ROOTFS_DIR}/dev
umount ${ROOTFS_DIR}/proc

# 打包
rm ${ROOTFS_DIR}/setup.sh
tar -czf ${OUTPUT_TAR} -C ${ROOTFS_DIR} .
rm -rf ${ROOTFS_DIR}

echo "✅ 完成: ${OUTPUT_TAR}"
