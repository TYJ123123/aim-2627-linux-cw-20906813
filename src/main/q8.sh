#!/bin/bash
# Q8：识别目标采集器、正常停止它、保留其他进程、修复 HTTP 配置并恢复服务。
# 用法：bash q8.sh INPUT_DIRECTORY OUTPUT_DIRECTORY repair|cleanup
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}
action=${3:?需要动作 repair 或 cleanup}

# ---- Q8 实现 ----
# 单次调用限 15 秒，所有等待循环都用很小的间隔。

# 进程是否仍"活着"。
# 不能用 kill -0：僵尸进程（state=Z）尚未被父进程回收，
# kill -0 对它仍返回成功。而 worker 由测试器的 Popen 收养、
# 回收时机不由本脚本决定，因此必须显式把 Z 当作已结束，
# 否则等待循环会一直空转、撞上 15 秒上限。
alive() {
    [ -r "/proc/$1/stat" ] || return 1
    st=$(awk '{print $3}' "/proc/$1/stat" 2>/dev/null || echo GONE)
    [ "$st" != "Z" ] && [ "$st" != "GONE" ]
}

# 等某 PID 结束（最多约 3 秒），超时则补 SIGKILL 再等约 0.5 秒
wait_pid_exit() {
    pid=$1
    i=0
    while alive "$pid"; do
        i=$((i + 1))
        [ "$i" -ge 150 ] && break
        sleep 0.02
    done
    if alive "$pid"; then
        kill -KILL "$pid" 2>/dev/null || true
        i=0
        while alive "$pid"; do
            i=$((i + 1))
            [ "$i" -ge 25 ] && break
            sleep 0.02
        done
    fi
}

if [ "$action" = "repair" ]; then
    # 1) 载入测试器生成的参数
    set -a
    # shellcheck source=/dev/null
    . "$input/process.env"
    set +a

    # 2) 进程识别（3 分）：输出 pid/user/state/command 四行 key=value
    mkdir -p "$output"
    {
        printf 'pid=%s\n' "$TARGET_PID"
        printf 'user=%s\n' "$(id -un)"
        # ps 的 state 首字母 R=运行 / S=睡眠，测试要求以 R 或 S 开头
        printf 'state=%s\n' "$(ps -o state= -p "$TARGET_PID" | tr -d ' ')"
        # 命令行里的换行折成空格，避免破坏 key=value 的单行格式
        printf 'command=%s\n' "$(tr '\0' ' ' < "/proc/$TARGET_PID/cmdline" | tr -s ' ' | sed 's/ $//')"
    } > "$output/process.txt"

    # 3) 采集日志（2 分）：抓够两条 TICK 作为样本
    {
        i=0
        while [ "$(grep -c "TICK $TARGET_TOKEN " "$WORKER_LOG" 2>/dev/null || true)" -lt 2 ]; do
            i=$((i + 1))
            [ "$i" -ge 100 ] && break
            sleep 0.02
        done
        grep "TICK $TARGET_TOKEN " "$WORKER_LOG" 2>/dev/null || true
    } > "$output/collector-sample.log"

    # 4) 正常停止（3 分）：SIGTERM 让 worker 走 stop() 分支并写下 STOP 记录
    kill -TERM "$TARGET_PID"
    wait_pid_exit "$TARGET_PID"
    # 5) 保留其他进程（2 分）：全程只针对 TARGET_PID，绝不用 killall/pkill

    # 6) 修复配置（3 分）：写回正确的 bind/port/route，须与期望逐字节一致
    cfg="$output/server.conf"
    printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' "$TARGET_PORT" > "$cfg"

    # 7) 停掉原错误服务
    #    必须用环境变量 SERVICE_PID —— 旧服务的状态目录不在 $output 下，
    #    去 $output/service/pid 读会得到空值，等于根本没杀。
    kill -TERM "$SERVICE_PID" 2>/dev/null || true
    wait_pid_exit "$SERVICE_PID"

    # 等端口真正释放（用 ss 判断，不能用 curl：
    # wrong-route 时旧服务仍在监听、只是路由不对，curl 会拿到 404 而被误判为“已释放”）
    i=0
    while ss -lnt 2>/dev/null | grep -q ":$TARGET_PORT "; do
        i=$((i + 1))
        [ "$i" -ge 100 ] && break
        sleep 0.02
    done

    # 8) HTTP 恢复（4 分）：用教师工具在正确端口/路由上重新起服务
    rm -rf "$output/service"
    bash "$START_TOOL" "$cfg" "$output/service"

    # 等就绪，再 curl（--noproxy 让本机请求绕过任何代理设置）
    i=0
    while ! curl -s --noproxy '*' --max-time 1 -o /dev/null \
            "http://127.0.0.1:$TARGET_PORT/status" 2>/dev/null; do
        i=$((i + 1))
        [ "$i" -ge 100 ] && break
        sleep 0.02
    done

    curl -s --noproxy '*' -o "$output/http-body.txt" -w '%{http_code}' \
        "http://127.0.0.1:$TARGET_PORT/status" > "$output/http-status.txt"
    printf '\n' >> "$output/http-status.txt"

elif [ "$action" = "cleanup" ]; then
    # 9) 服务清理（3 分）：cleanup 才停止服务；repair 阶段必须让它继续跑。
    #    优先读本次 repair 写下的 pid 文件，读不到就回退到环境变量。
    svcpid=$(cat "$output/service/pid" 2>/dev/null || true)
    if [ -z "$svcpid" ]; then
        set -a
        # shellcheck source=/dev/null
        . "$input/process.env"
        set +a
        svcpid="$SERVICE_PID"
    fi
    kill -TERM "$svcpid" 2>/dev/null || true
    wait_pid_exit "$svcpid"

    # 确认端口已释放
    i=0
    while ss -lnt 2>/dev/null | grep -q ":$TARGET_PORT "; do
        i=$((i + 1))
        [ "$i" -ge 100 ] && break
        sleep 0.02
    done
fi
