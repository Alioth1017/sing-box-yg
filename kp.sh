#!/bin/bash
# 定时设置：*/10 * * * * /bin/bash /root/kp.sh 每10分钟运行一次
# 如果你已安装了Serv00本地SSH脚本，不要再运行此脚本部署了，这样会造成进程爆满，必须二选一！
# serv00变量添加规则：
# 如使用保活网页，请不要启用cron，以防止cron与网页保活重复运行造成进程爆满
# 请通过环境变量 ACCOUNTS_JSON 提供 JSON 数组，避免把账号、密码和 Token 写进脚本文件。
# 可选：通过 KNOWN_HOSTS 提供 SSH known_hosts 内容；通过 RAW_REPO_URL 指定已审计脚本来源。
ACCOUNTS=${ACCOUNTS_JSON:-${ACCOUNTS:-}}
RAW_REPO_URL=${RAW_REPO_URL:-https://raw.githubusercontent.com/Alioth1017/sing-box-yg/main}

if [[ -z "$ACCOUNTS" ]]; then
  echo "请先设置 ACCOUNTS_JSON 环境变量"
  exit 1
fi

validate_required() {
  local value=$1
  local field_name=$2
  if [[ -z "$value" ]]; then
    echo "$field_name 不能为空"
    exit 1
  fi
}

validate_regex() {
  local value=$1
  local pattern=$2
  local field_name=$3
  if [[ -n "$value" && ! "$value" =~ $pattern ]]; then
    echo "$field_name 格式无效"
    exit 1
  fi
}

setup_ssh_options() {
  SSH_OPTIONS=(-o StrictHostKeyChecking=accept-new)
  if [[ -n "${KNOWN_HOSTS:-}" ]]; then
    local known_hosts_file="${TMPDIR:-/tmp}/sing-box-yg-known-hosts"
    printf '%s\n' "$KNOWN_HOSTS" > "$known_hosts_file"
    chmod 600 "$known_hosts_file"
    SSH_OPTIONS=(-o StrictHostKeyChecking=yes -o UserKnownHostsFile="$known_hosts_file")
  fi
}

setup_ssh_options

run_remote_command() {
local RES=$1
local REP=$2
local SSH_USER=$3
local SSH_PASS=$4
local REALITY=${5}
local SUUID=$6
local TCP1_PORT=$7
local TCP2_PORT=$8
local UDP_PORT=$9
local HOST=${10}
local ARGO_DOMAIN=${11}
local ARGO_AUTH=${12}
  if [ -z "${ARGO_DOMAIN}" ]; then
    echo "Argo域名为空，申请Argo临时域名"
  else
    echo "Argo已设置固定域名：${ARGO_DOMAIN}"
  fi
  printf -v remote_command 'export reym=%q UUID=%q vless_port=%q vmess_port=%q hy2_port=%q reset=%q resport=%q ARGO_DOMAIN=%q ARGO_AUTH=%q RAW_REPO_URL=%q && bash <(curl -Ls %q/serv00keep.sh)' \
    "$REALITY" "$SUUID" "$TCP1_PORT" "$TCP2_PORT" "$UDP_PORT" "$RES" "$REP" "$ARGO_DOMAIN" "$ARGO_AUTH" "$RAW_REPO_URL" "$RAW_REPO_URL"
  sshpass -p "$SSH_PASS" ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$HOST" "$remote_command"
}
if  cat /etc/issue /proc/version /etc/os-release 2>/dev/null | grep -q -E -i "openwrt"; then
opkg update
opkg install sshpass curl jq
else
    if [ -f /etc/debian_version ]; then
        package_manager="apt-get install -y"
        apt-get update >/dev/null 2>&1
    elif [ -f /etc/redhat-release ]; then
        package_manager="yum install -y"
    elif [ -f /etc/fedora-release ]; then
        package_manager="dnf install -y"
    elif [ -f /etc/alpine-release ]; then
        package_manager="apk add"
    fi
    $package_manager sshpass curl jq cron >/dev/null 2>&1 &
fi
echo "*****************************************************"
echo "*****************************************************"
echo "甬哥Github项目  ：github.com/yonggekkk"
echo "甬哥Blogger博客 ：ygkkk.blogspot.com"
echo "甬哥YouTube频道 ：www.youtube.com/@ygkkk"
echo "自动远程部署Serv00三合一协议脚本【VPS+软路由】"
echo "版本：V25.3.26"
echo "*****************************************************"
echo "*****************************************************"
              count=0  
           for account in $(echo "${ACCOUNTS}" | jq -c '.[]'); do
              count=$((count+1))
              RES=$(echo $account | jq -r '.RES')
              REP=$(echo $account | jq -r '.REP')              
              SSH_USER=$(echo $account | jq -r '.SSH_USER')
              SSH_PASS=$(echo $account | jq -r '.SSH_PASS')
              REALITY=$(echo $account | jq -r '.REALITY')
              SUUID=$(echo $account | jq -r '.SUUID')
              TCP1_PORT=$(echo $account | jq -r '.TCP1_PORT')
              TCP2_PORT=$(echo $account | jq -r '.TCP2_PORT')
              UDP_PORT=$(echo $account | jq -r '.UDP_PORT')
              HOST=$(echo $account | jq -r '.HOST')
              ARGO_DOMAIN=$(echo $account | jq -r '.ARGO_DOMAIN')
                ARGO_AUTH=$(echo $account | jq -r '.ARGO_AUTH')
                validate_required "$RES" "RES"
                validate_required "$REP" "REP"
                validate_required "$SSH_USER" "SSH_USER"
                validate_required "$SSH_PASS" "SSH_PASS"
                validate_required "$HOST" "HOST"
                validate_regex "$SSH_USER" '^[A-Za-z0-9._-]+$' "SSH_USER"
                validate_regex "$HOST" '^[A-Za-z0-9.-]+$' "HOST"
                validate_regex "$REALITY" '^[A-Za-z0-9.-]*$' "REALITY"
                validate_regex "$SUUID" '^$|^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' "SUUID"
                validate_regex "$TCP1_PORT" '^$|^[0-9]{1,5}$' "TCP1_PORT"
                validate_regex "$TCP2_PORT" '^$|^[0-9]{1,5}$' "TCP2_PORT"
                validate_regex "$UDP_PORT" '^$|^[0-9]{1,5}$' "UDP_PORT"
                validate_regex "$ARGO_DOMAIN" '^[A-Za-z0-9.-]*$' "ARGO_DOMAIN"
                validate_regex "$ARGO_AUTH" '^[A-Za-z0-9._=-]*$' "ARGO_AUTH"
              if sshpass -p "$SSH_PASS" ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$HOST" -q exit; then
            echo "🎉恭喜！✅第【$count】台服务器连接成功！🚀服务器地址：$HOST ，账户名：$SSH_USER"   
          if [ -z "${ARGO_DOMAIN}" ]; then
           check_process="ps aux | grep '[c]onfig' > /dev/null && ps aux | grep [l]ocalhost:$TCP2_PORT > /dev/null"
            else
           check_process="ps aux | grep '[c]onfig' > /dev/null && ps aux | grep '[t]oken $ARGO_AUTH' > /dev/null"
           fi
          if ! sshpass -p "$SSH_PASS" ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$HOST" "$check_process" || [[ "$RES" =~ ^[Yy]$ ]]; then
            echo "⚠️检测到主进程或者argo进程未启动，或者执行重置"
             echo "⚠️现在开始修复或重置部署……请稍等"
             if run_remote_command "$RES" "$REP" "$SSH_USER" "$SSH_PASS" "${REALITY}" "$SUUID" "$TCP1_PORT" "$TCP2_PORT" "$UDP_PORT" "$HOST" "${ARGO_DOMAIN}" "$ARGO_AUTH"; then
               echo "✅远程修复或重置执行完成"
             else
               echo "远程修复或重置执行失败"
               exit 1
             fi
          else
            echo "🎉恭喜！✅检测到所有进程正常运行中 "
            SSH_USER_LOWER=$(echo "$SSH_USER" | tr '[:upper:]' '[:lower:]')
            sshpass -p "$SSH_PASS" ssh "${SSH_OPTIONS[@]}" "$SSH_USER@$HOST" "
            echo \"配置显示如下：\"
            cat domains/${SSH_USER_LOWER}.serv00.net/logs/list.txt
            echo \"====================================================\""
            fi
           else
            echo "===================================================="
            echo "💥杯具！❌第【$count】台服务器连接失败！🚀服务器地址：$HOST ，账户名：$SSH_USER"
            echo "⚠️可能账号名、密码、服务器名称输入错误，或者当前服务器在维护中"  
            echo "===================================================="
           fi
            done
