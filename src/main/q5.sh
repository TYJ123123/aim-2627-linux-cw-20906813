#!/bin/bash
# Q5：运行启动前检查，分别记录 stdout/stderr/真实退出码，并生成诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# ---- Q5 实现 ----

# 1) 载入本次场景生成的参数（.env 由测试器提供）
#    set -a 使后续赋值自动导出，无需逐个 export。
set -a
# shellcheck source=/dev/null
. "$input/launch.env"
set +a

# 2) 分别捕获 stdout 与 stderr，并保留真实退出码
#    关键：不能用 `cmd || true`，那会把 $? 覆盖成 0；
#    必须先关掉 errexit 捕获码，再自行处理。
set +e
"$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" > "$output/stdout.log" 2> "$output/stderr.log"
code=$?
set -e

# 3) 记录真实退出码
printf '%s\n' "$code" > "$output/exit-code.txt"

# 4) 诊断报告（3 分）：按退出码映射结论，与题面契约逐字符一致
case "$code" in
    0)  result=SUCCESS; reason=NONE ;;
    10) result=FAILED;  reason=MODEL_MISSING ;;
    20) result=FAILED;  reason=CAMERA_DENIED ;;
    *)  result=FAILED;  reason=UNKNOWN ;;
esac
printf 'result=%s\nexit_code=%s\nreason=%s\n' "$result" "$code" "$reason" > "$output/report.txt"

# 5) 无论检查程序成败，答题脚本都以 0 正常退出
exit 0
