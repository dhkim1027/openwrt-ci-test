# OpenWrt 최상위 Makefile 구조를 흉내낸 시험용
# 실제 OpenWrt는 훨씬 복잡하지만 CI 파이프라인 검증 목적으로는 충분

TOPDIR := $(CURDIR)
DL_DIR := $(TOPDIR)/dl
BUILD_DIR := $(TOPDIR)/build_dir
STAGING_DIR := $(TOPDIR)/staging_dir
BIN_DIR := $(TOPDIR)/bin/targets

CC ?= gcc
CFLAGS := -O2 -Wall -Wextra
LDFLAGS :=

# .config 파일에서 설정 읽기 (OpenWrt 스타일)
-include .config

CUSTOMER ?= unknown
VERSION ?= 0.0.0

.PHONY: all defconfig download feeds build clean distclean install

# 기본 타겟
all: build

# .config 가 없으면 안내
.config:
	@echo "ERROR: .config 파일이 없습니다."
	@echo "       configs/<customer>.config 를 .config 로 복사하세요."
	@exit 1

# defconfig: .config 검증/정규화 (OpenWrt 흉내)
defconfig: .config
	@echo "=== defconfig ==="
	@echo "CUSTOMER=$(CUSTOMER)"
	@echo "VERSION=$(VERSION)"
	@mkdir -p $(BUILD_DIR) $(STAGING_DIR) $(BIN_DIR) $(DL_DIR)
	@touch $(BUILD_DIR)/.configured
	@echo "defconfig 완료"

# download: dl/ 캐시에 소스 받기 흉내 (실제로는 빈 파일 생성)
download: defconfig
	@echo "=== download (dl/ 캐시 사용) ==="
	@./scripts/download.sh $(DL_DIR)

# 빌드 단계
build: download
	@echo "=== build ==="
	@echo "컴파일: src/app.c, src/lib.c"
	$(CC) $(CFLAGS) -c src/lib.c -o $(BUILD_DIR)/lib.o
	$(CC) $(CFLAGS) -c src/app.c -o $(BUILD_DIR)/app.o
	$(CC) $(BUILD_DIR)/app.o $(BUILD_DIR)/lib.o -o $(BUILD_DIR)/app $(LDFLAGS)
	@echo "=== install ==="
	@mkdir -p $(BIN_DIR)/$(CUSTOMER)
	cp $(BUILD_DIR)/app $(BIN_DIR)/$(CUSTOMER)/app-$(VERSION)
	@echo "$(CUSTOMER) $(VERSION) $$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
		> $(BIN_DIR)/$(CUSTOMER)/build-info.txt
	@echo ""
	@echo "=== 빌드 완료 ==="
	@ls -lh $(BIN_DIR)/$(CUSTOMER)/

# 정리
clean:
	rm -rf $(BUILD_DIR) $(STAGING_DIR) $(BIN_DIR)

distclean: clean
	rm -rf $(DL_DIR) .config
