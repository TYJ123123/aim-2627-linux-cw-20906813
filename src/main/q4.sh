#!/bin/bash
# Q4：合并 boot/run 日志，按级别字段提取错误与告警，生成六份统计产物。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# ---- Q4 实现 ----
boot="$input/boot.log"
run="$input/run.log"

# 1) 合并（2 分）：boot 在前、run 在后，逐字节拼接
cat -- "$boot" "$run" > "$output/all.log"

# 2) 错误提取（4 分）：级别是行首第一个字段，必须锚定 "^ERROR "
#    消息正文里出现 ERROR（如 "launcher previous ERROR has been handled"）不算错误行。
#    无匹配时 grep 返回 1，配合 set -e 会中断脚本，因此必须 || true。
{ grep '^ERROR ' "$output/all.log" || true; } > "$output/errors.log"

# 3) 告警提取（3 分）：行首为 WARN 或 ERROR 的行
{ grep -E '^(WARN|ERROR) ' "$output/all.log" || true; } > "$output/attention.log"

# 4) 末尾日志（2 分）：最后 5 行（不足 5 行时给出全部）
tail -n 5 "$output/all.log" > "$output/recent.log"

# 5) 首条错误（2 分）：前 3 条错误行
head -n 3 "$output/errors.log" > "$output/first-errors.log"

# 6) 错误计数（2 分）
#    不要用 wc -l 数行：它统计换行符个数，末尾缺换行会漏计，
#    而靠 printf 补换行又会让空结果被算成 1 行。
#    grep -c 直接统计匹配行数，天然规避这两个问题。
grep -c '^ERROR ' "$output/all.log" > "$output/error-count.txt" 2>/dev/null || true
