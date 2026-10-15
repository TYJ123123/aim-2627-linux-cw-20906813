#!/bin/bash
# Q3：复制素材、备份配置、移动草稿、删除 tmp、设定权限并直接运行 hello.sh。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

# ---- Q3 实现 ----
ws="$output/sentry_ws"

# 关键前提：输入目录由测试器以 root 拥有，学生脚本对它没有写权限。
# 因此所有移动/删除都只能发生在输出工作区内部，绝不能改动 "$input"。

# 0) 先清空重建，保证两次运行产物完全一致。
#    测试会在输出里预置 sentry_ws/tmp/cache.txt 作为陷阱：
#    若只做"目录已存在就跳过"，它会残留，第二次比对必然失败。
rm -rf "$ws"
mkdir -p "$ws/scripts" "$ws/config" "$ws/backup" "$ws/archive" "$ws/logs"

# 1) 复制和备份（3 分）
#    先复制、后 chmod：backup/robot.conf 保持输入原样（644），
#    不跟着 config/robot.conf 一起被改成 640。
cp -- "$input/hello.sh"   "$ws/scripts/hello.sh"
cp -- "$input/robot.conf" "$ws/config/robot.conf"
cp -- "$input/robot.conf" "$ws/backup/robot.conf"

# 2) 移动归档（2 分）
#    先把草稿放进工作区的 config/，再在工作区内 mv 到 archive/ 改名，
#    因此 config/draft.conf 不存在、archive/draft.conf.old 内容与输入一致。
cp -- "$input/draft.conf" "$ws/config/draft.conf"
mv -- "$ws/config/draft.conf" "$ws/archive/draft.conf.old"

# 3) 删除临时目录（1 分）：连带预置的 cache.txt 一起清掉
rm -rf "$ws/tmp"

# 4) 精确权限（2 分）：750 = rwxr-x---，本身已含 owner 执行位。
#    不要再用 chmod +x —— 那会给所有类别加执行位，把 750 变成 751。
chmod 750 "$ws/scripts/hello.sh"
chmod 640 "$ws/config/robot.conf"

# 5) 执行脚本（2 分）：750 已可执行（属主），直接执行并保存 stdout
"$ws/scripts/hello.sh" > "$output/hello-output.txt"
