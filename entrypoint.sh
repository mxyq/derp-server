#!/bin/sh
set -eu

log() {
    printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

if [ -z "${HOSTNAME}" ]; then
    log "ERROR: HOSTNAME environment variable is required!" >&2
    exit 1
fi

CONF_PATH="/tmp/derper.conf"

log "Starting DERP server bootstrap"
log "HOSTNAME=${HOSTNAME}"
log "Config file path: ${CONF_PATH}"
log "Listen address: :8080"
log "HTTP port: 8080"
log "STUN port: 3478"
log "Generating a secure, random NodePrivate key..."
# 1. 生成 32 字节的随机十六进制字符串
HEX_KEY=$(head -c 32 /dev/urandom | od -An -vtx1 | tr -d ' \n')
# 2. 拼接新版 derper 要求的 "privkey:" 前缀
RANDOM_KEY="privkey:${HEX_KEY}"
log "Generated NodePrivate key: ${RANDOM_KEY}"

log "Generating DERP config file at ${CONF_PATH}..."

# 动态生成符合新版 derper 规范的最小化 JSON 配置文件
# 注意：新版私钥如果不存在，derper 会自动在这个文件中生成并补全 "PrivateKey" 字段
cat << EOF > "$CONF_PATH"
{
  "Version": 1,
  "HostName": "${HOSTNAME}",
  "PrivateKey": "${RANDOM_KEY}",
  "OmitCert": true
}
EOF

log "DERP config file generated successfully"
log "DERP config content:\n$(cat "$CONF_PATH")"
log "Starting DERP server with config file..."

# 使用 exec 替换当前进程，传入生成的配置文件路径
log "Executing: /derper -c ${CONF_PATH} -a :8080 -http-port 8080 -stun-port 3478"
exec /derper \
    -c "$CONF_PATH" \
    -a ":8080" \
    -http-port 8080 \
    -stun-port 3478