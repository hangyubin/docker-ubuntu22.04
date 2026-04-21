# 使用一个最新的稳定版 Ubuntu 作为基础镜像
FROM ubuntu:22.04

# 更换国内源 (可选，用于加速下载)
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 设置语言环境
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 更新软件源并安装 systemd 和 dbus
RUN apt-get update && \
    apt-get install -y systemd dbus && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 为了容器环境，屏蔽一些不必要的 systemd 服务，避免启动报错
RUN systemctl mask \
    dev-mqueue.mount \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    sys-fs-fuse-connections.mount \
    display-manager.service \
    graphical.target

# 如果需要 SSH，取消下面的注释
# RUN apt-get update && \
#     apt-get install -y openssh-server && \
#     ssh-keygen -A && \
#     echo "root:123456" | chpasswd && \
#     sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# 声明容器启动命令为 systemd
CMD ["/lib/systemd/systemd"]
