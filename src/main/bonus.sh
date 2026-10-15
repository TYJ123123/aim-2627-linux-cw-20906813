#!/bin/bash
# Bonus：用 tmux 分离会话托管采集器，脚本返回后日志继续增长，stop 时清理。
# 用法：bash bonus.sh INPUT_DIRECTORY OUTPUT_DIRECTORY start|stop
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}
action=${3:?需要动作 start 或 stop}

# ---- Bonus 实现 ----

# 载入测试器生成的参数（TMUX_SOCKET / SESSION / TOKEN / WORKER_TOOL）
set -a
# shellcheck source=/dev/null
. "$input/bonus.env"
set +a

log="$output/bonus.log"

if [ "$action" = "start" ]; then
    mkdir -p "$output"

    # 1) 分离的会话（4 分）
    #    -L "$TMUX_SOCKET" 指定本次测试专属 socket，避免与其他会话互相干扰。
    #    new-session -d 建立分离会话；会话内命令跑完默认会关闭会话，
    #    所以末尾接 exec bash 让会话保持存活，供 stop 阶段定位与清理。
    #    日志交给 worker.py 自己写（--log），不在这里做重定向 ——
    #    worker.py 用行缓冲写入，日志才会稳定、可观测地增长。
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" \
        "python3 '$WORKER_TOOL' --token '$TOKEN' --log '$log'; exec bash"

elif [ "$action" = "stop" ]; then
    # 2) 停止与清理（2 分）
    #    从日志 START 行取回 pid，按 PID 精确终止该采集器。
    #    测试用的 token 形态是 bonus-<pid>，因此用 token 反推 pid 不可靠，
    #    以日志记录为准更稳。
    target_pid=$(grep -m1 '^START ' "$log" 2>/dev/null | sed 's/.*pid=//' || true)
    if [ -n "$target_pid" ]; then
        kill -TERM "$target_pid" 2>/dev/null || true
        for _ in $(seq 1 50); do
            if ! kill -0 "$target_pid" 2>/dev/null; then break; fi
            sleep 0.1
        done
    fi

    # 关掉专属 tmux 服务端，连同会话一起清理。
    # 注意：不要删除 bonus.log —— 测试会在 stop 之后读取它确认 STOP 记录。
    tmux -L "$TMUX_SOCKET" kill-server 2>/dev/null || true
fi
