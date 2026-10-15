#!/bin/bash
# Q7：写 ssh_config（别名 + 严格校验 + 指定密钥），执行远端 whoami，用 SCP 取回日志。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?输出目录}

# ---- Q7 实现 ----

# 1) 载入测试器生成的连接参数（含 HOST/PORT/REMOTE_USER/KEY_PATH/KNOWN_HOSTS/REMOTE_LOG）
set -a
# shellcheck source=/dev/null
. "$input/remote.env"
set +a

# 2) 客户端配置（3 分）
#    路径必须加引号：测试目录名含空格（"aim-linux public tests"），
#    不加引号 ssh 会报 "keyword identityfile extra arguments at end of line"。
cfg="$output/ssh_config"
{
    printf 'Host aim-sentry\n'
    printf '    HostName %s\n' "$HOST"
    printf '    Port %s\n' "$PORT"
    printf '    User %s\n' "$REMOTE_USER"
    printf '    IdentityFile "%s"\n' "$KEY_PATH"
    printf '    UserKnownHostsFile "%s"\n' "$KNOWN_HOSTS"
    printf '    StrictHostKeyChecking yes\n'
    printf '    IdentitiesOnly yes\n'
} > "$cfg"
chmod 600 "$cfg"

# 3) 远程命令（3 分）：用别名登录并记录 whoami 输出
ssh -F "$cfg" -o BatchMode=yes aim-sentry whoami > "$output/remote-user.txt"

# 4) 远程日志传输（4 分）：用 SCP 取回，落到 received/errors.log
#    直接复用上面那份 ssh_config（-F "$cfg"）：认证方式、密钥、
#    known_hosts、端口都已生效，与第 3 步的 ssh 完全一致，
#    不必再重复一套 -i/-o 参数。
mkdir -p "$output/received"
scp -q -F "$cfg" "aim-sentry:$REMOTE_LOG" "$output/received/errors.log"
