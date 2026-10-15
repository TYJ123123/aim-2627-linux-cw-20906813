#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?输出目录}

# ---- Q6 实现 ----
# 要求：不用 sudo、不联网，把 .deb 真正"安装"进自己的 sysroot。
# 关键点是用 dpkg 的 --root 把整个安装根指向 output/sysroot，
# 这样 dpkg 数据库落在 sysroot/var/lib/dpkg，与验收用的 --admindir 一致。
# 单纯解压压缩包不算安装（数据库里不会有记录）。

root="$output/sysroot"
mkdir -p "$root"

deb="$input/aim-sentry-tools.deb"

# --force-not-root : 允许以普通用户身份安装
# --log=/dev/null  : 不写默认日志文件（既无权限也没必要）
dpkg --root="$root" --force-not-root --log=/dev/null -i "$deb"

# 运行安装后的工具，保存 stdout
"$root/usr/bin/aim-sentry-info" > "$output/tool-output.txt"
