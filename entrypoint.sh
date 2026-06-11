#!/bin/sh
set -eu

if [ -z "${HOSTNAME}" ]; then
    echo "ERROR: HOSTNAME environment variable is required!" >&2
    exit 1
fi

CONF_PATH="/tmp/derper.conf"

echo "Generating a secure, random NodePrivate key..."
# 1. 生成 32 字节的随机十六进制字符串
HEX_KEY=$(head -c 32 /dev/urandom | od -An -vtx1 | tr -d ' \n')
# 2. 拼接新版 derper 要求的 "privkey:" 前缀
RANDOM_KEY="privkey:${HEX_KEY}"

echo "Generating derper config file at ${CONF_PATH}..."

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

echo "Starting DERP server with config file..."

# 使用 exec 替换当前进程，传入生成的配置文件路径
exec /derper \
    -c "$CONF_PATH" \
    -a ":8080" \
    -http-port 8080 \
    -stun-port 3478