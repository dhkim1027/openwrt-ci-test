# OpenWrt CI 시험용 프로젝트

OpenWrt + Docker + Jenkins 빌드 파이프라인을 빠르게 시험하기 위한 더미 프로젝트입니다.
실제 OpenWrt 빌드 구조를 흉내냈지만 빌드는 수십 초 안에 끝납니다.

## 구조

```
.
├── Dockerfile           # 빌드 환경 (OpenWrt Dockerfile 흉내)
├── Jenkinsfile          # CI 파이프라인
├── Makefile             # OpenWrt top-level make 흉내
├── configs/             # 고객사별 빌드 설정
│   ├── customer-a.config
│   └── customer-b.config
├── scripts/
│   ├── feeds.sh         # ./scripts/feeds 흉내
│   └── download.sh      # dl/ 캐시 흉내
└── src/                 # 실제 빌드되는 C 소스
    ├── app.c
    ├── lib.c
    └── lib.h
```

## 로컬에서 직접 빌드 (Docker 없이)

```bash
cp configs/customer-a.config .config
./scripts/feeds.sh update -a
./scripts/feeds.sh install -a
make defconfig
make
./bin/targets/customer-a/app-1.0.0 World
```

## 로컬에서 Docker로 빌드 (Jenkins와 동일한 방식)

```bash
# 이미지 빌드
docker build -t openwrt-ci-test-builder .

# 캐시 디렉토리 준비
mkdir -p /tmp/dl-cache /tmp/ccache

# 빌드 실행
cp configs/customer-a.config .config
docker run --rm \
    -v $(pwd):/src \
    -v /tmp/dl-cache:/src/dl \
    -v /tmp/ccache:/ccache \
    -w /src \
    --user $(id -u):$(id -g) \
    openwrt-ci-test-builder \
    bash -c './scripts/feeds.sh update -a && \
             ./scripts/feeds.sh install -a && \
             make defconfig && make'
```

## Jenkins 설정

1. **Multibranch Pipeline** 또는 **Pipeline** Job 생성
2. SCM: 이 repo URL 지정
3. Script Path: `Jenkinsfile` (기본값)
4. 빌드 시 파라미터로 `CUSTOMER` 선택

## Jenkins 에이전트 요구사항

- Docker 설치되어 있어야 함
- jenkins 유저가 docker 그룹에 속해야 함:
  ```
  sudo usermod -aG docker jenkins
  sudo systemctl restart jenkins
  ```
- 캐시 디렉토리 미리 생성 + 권한 부여:
  ```
  sudo mkdir -p /var/jenkins_cache/{dl,ccache}
  sudo chown -R jenkins:jenkins /var/jenkins_cache
  ```

## 검증 포인트

이 시험으로 확인할 수 있는 것들:

- [ ] Jenkins에서 git clone 정상 동작
- [ ] Dockerfile 기반 빌드 이미지 생성
- [ ] Dockerfile 변경 없을 시 이미지 재사용 (캐시)
- [ ] 컨테이너 안에서 빌드 수행
- [ ] `dl/` 캐시 호스트 공유 (2회차 빌드 시 download 스킵 확인)
- [ ] 산출물이 호스트 워크스페이스로 추출됨
- [ ] 권한 문제 없이 정리 가능
- [ ] `CLEAN_BUILD=true` 시 워크스페이스 청소 동작
- [ ] 고객사별 설정으로 다른 산출물 생성
