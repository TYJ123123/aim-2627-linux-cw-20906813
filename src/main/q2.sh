#!/bin/bash
# Q2：创建 sentry_ws 四个子目录、两个空文件以及指定脚本和配置。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
# Q2 的产物内容全部由本脚本内联生成，不读取输入素材；
# input 仍按统一接口接收并做非空校验，故此处显式标记为有意未使用。
# shellcheck disable=SC2034
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# ---- Q2 实现 ----
# 注意：本题输入目录为空，hello.sh 与 robot.conf 的内容必须由本脚本内联生成。

ws="$output/sentry_ws"

# 1) 目录结构（4 分）：四个普通子目录（mkdir -p 幂等，重复运行不报错）
mkdir -p "$ws/scripts" "$ws/config" "$ws/logs" "$ws/tmp"

# 2) 空文件（2 分）：必须是零字节普通文件（用 : > 截断，不能用 mkdir）
: > "$ws/logs/.keep"
: > "$ws/tmp/scratch.txt"

# 3) 启动脚本（2 分）：内容必须逐字节等于期望值
printf '%s\n' '#!/bin/bash' 'echo "Hello, AIM Linux!"' > "$ws/scripts/hello.sh"

# 4) 配置文本（2 分）：三行配置，逐字节匹配
printf '%s\n' 'robot=sentry' 'mode=training' 'log_level=INFO' > "$ws/config/robot.conf"
