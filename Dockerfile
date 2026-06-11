# ==========================================
# 阶段 1: 编译构建 (使用最新的 Golang 镜像保持编译器最新)
# ==========================================
FROM golang:alpine AS builder

# ENV GOPROXY="https://goproxy.cn,direct"
ENV  CGO_ENABLED=0 \
    GOOS=linux \
    GOFLAGS="-trimpath"

# 安装 git 并拉取最新版 derper
RUN apk add --no-cache git && \
    go install tailscale.com/cmd/derper@main

# ==========================================
# 阶段 2: 最终运行镜像 (使用最新的 Alpine 确保系统补丁最新)
# ==========================================
FROM alpine:latest

# 从构建阶段复制最新的二进制文件
COPY --from=builder /go/bin/derper /derper
COPY entrypoint.sh /entrypoint.sh

# 严格限制文件权限，防止容器运行时被篡改
# 核心安全加固：即使基础镜像在变，非 root 用户的权限屏障依然有效
RUN chmod 555 /entrypoint.sh /derper && \
    addgroup -g 10001 -S derp && \
    adduser -u 10001 -S derp -G derp

# 切换到非 root 用户
USER 10001

ENV HOSTNAME=""
EXPOSE 8080/tcp 3478/udp

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:8080/derp/probe || exit 1

ENTRYPOINT ["/entrypoint.sh"]