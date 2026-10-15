#!/bin/bash
# Q1：定位 handover，读取隐藏编号和欢迎文本。输出 location.txt、robot-id.txt、welcome.txt。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# ---- Q1 实现 ----

# 1) 路径定位（4 分）：location.txt 必须是 handover 目录的「真实绝对路径 + 换行」
handover="$input/handover"
mkdir -p "$output"
realpath -- "$handover" > "$output/location.txt"

# 2) 隐藏文件（3 分）：读出隐藏文件 .robot-id 的原文
cat -- "$handover/.robot-id" > "$output/robot-id.txt"

# 3) 文本读取（3 分）：逐字复制欢迎文本
cat -- "$input/notes/welcome.txt" > "$output/welcome.txt"
