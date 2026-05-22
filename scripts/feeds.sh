#!/bin/bash
# OpenWrt 의 ./scripts/feeds 를 흉내낸 더미 스크립트
# 실제 동작은 안 하고 명령 흐름만 시뮬레이션

set -e

ACTION="$1"

case "$ACTION" in
    update)
        echo "[feeds] update 시작"
        sleep 1
        echo "[feeds] update 완료"
        ;;
    install)
        echo "[feeds] install 시작"
        sleep 1
        echo "[feeds] install 완료"
        ;;
    *)
        echo "사용법: $0 {update|install} [-a]"
        exit 1
        ;;
esac
