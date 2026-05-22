#!/bin/bash
# OpenWrt 의 dl/ 캐시 동작을 흉내낸 스크립트
# 처음 실행 시에는 "다운로드"하고, 캐시에 있으면 스킵

set -e

DL_DIR="${1:-./dl}"
mkdir -p "$DL_DIR"

# 가짜 의존 소스 목록
SOURCES=(
    "libfoo-1.2.3.tar.gz"
    "libbar-2.0.0.tar.gz"
    "toolchain-stub-4.5.tar.xz"
)

for src in "${SOURCES[@]}"; do
    if [ -f "$DL_DIR/$src" ]; then
        echo "[download] 캐시 사용: $src"
    else
        echo "[download] 다운로드 중: $src"
        # 다운로드 흉내 (1초 대기 + 더미 파일)
        sleep 1
        dd if=/dev/urandom of="$DL_DIR/$src" bs=1024 count=10 status=none
    fi
done

echo "[download] 모든 소스 준비 완료 ($DL_DIR)"
