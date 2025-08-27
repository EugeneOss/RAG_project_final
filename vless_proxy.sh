#!/bin/bash

CONFIG_PATH="$HOME/.config/xray"
CONFIG_FILE="$CONFIG_PATH/vless-config.json"
XRAY_BIN="/usr/local/bin/xray"
SERVICE_FILE="/etc/systemd/system/vless-proxy.service"

UUID="b780d050-1e1d-4473-8af1-414e73262057"
ADDRESS="germany47.yourbot.biz"
PORT=443
PBK="P2mNkmiEnivcnu81Xuge9q2n3ZdGGQNBB-N1WN7uqUw"
SNI="germany47.yourbot.biz"
SID="713fc1"
SPX="/"
FLOW="xtls-rprx-vision"

# Установка Xray, если не установлен
install_xray() {
    if ! command -v xray &> /dev/null; then
        echo "[+] Устанавливаю Xray-core..."
        bash <(curl -Ls https://github.com/XTLS/Xray-install/raw/main/install-release.sh)
    else
        echo "[*] Xray уже установлен."
    fi
}

# Генерация конфигурации
generate_config() {
    mkdir -p "$CONFIG_PATH"
    cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10808,
      "listen": "127.0.0.1",
      "protocol": "socks",
      "settings": {
        "udp": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$ADDRESS",
            "port": $PORT,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none",
                "flow": "$FLOW"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "fingerprint": "chrome",
          "serverName": "$SNI",
          "publicKey": "$PBK",
          "shortId": "$SID",
          "spiderX": "$SPX"
        }
      }
    }
  ]
}
EOF
    echo "[+] Конфигурация сохранена в $CONFIG_FILE"
}

# Создание systemd-сервиса
create_service() {
    sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=VLESS Proxy via Xray
After=network.target

[Service]
ExecStart=$XRAY_BIN run -c $CONFIG_FILE
Restart=on-failure
User=$USER

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reexec
    sudo systemctl daemon-reload
    sudo systemctl enable vless-proxy.service
    echo "[+] Сервис создан. Используйте 'start' и 'stop' ниже для управления."
}

# Старт сервиса
start_proxy() {
    sudo systemctl start vless-proxy.service
    echo "[+] VLESS прокси запущен на 127.0.0.1:10808"
}

# Стоп сервиса
stop_proxy() {
    sudo systemctl stop vless-proxy.service
    echo "[-] VLESS прокси остановлен."
}

# Статус
status_proxy() {
    sudo systemctl status vless-proxy.service
}

# UI
case "$1" in
    install)
        install_xray
        generate_config
        create_service
        ;;
    start)
        start_proxy
        ;;
    stop)
        stop_proxy
        ;;
    status)
        status_proxy
        ;;
    *)
        echo "Использование: $0 {install|start|stop|status}"
        ;;
esac
