# OpenWrt 빌드 환경을 흉내낸 시험용 Dockerfile
# 실제 OpenWrt Dockerfile과 구조적으로 비슷하지만 가벼움
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# OpenWrt 빌드에 필요한 패키지들 중 핵심만 (전체는 너무 많음)
# 실제 프로젝트 Dockerfile 작성 시 참고용
RUN apt-get update && apt-get install -y \
        build-essential \
        ccache \
        curl \
        file \
        git \
        make \
        wget \
        gcc \
        g++ \
        unzip \
        xxd \
    && rm -rf /var/lib/apt/lists/*

# Jenkins 에이전트 UID와 맞추기 위한 빌드 유저
# (필요 시 docker run --user 로 오버라이드 가능)
ARG BUILD_UID=1000
ARG BUILD_GID=1000
RUN groupadd -g ${BUILD_GID} builder || true && \
    useradd -m -u ${BUILD_UID} -g ${BUILD_GID} -s /bin/bash builder || true

WORKDIR /src

# 소스는 빌드 시 볼륨 마운트로 주입할 것이므로 COPY 하지 않음
CMD ["/bin/bash"]
