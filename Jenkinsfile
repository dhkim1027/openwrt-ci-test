// OpenWrt + Docker 빌드 CI 파이프라인 (시험용)
// 실제 프로젝트에서도 거의 같은 구조로 사용 가능

pipeline {
    agent any

    parameters {
        choice(
            name: 'CUSTOMER',
            choices: ['customer-a', 'customer-b'],
            description: '빌드할 고객사 선택'
        )
        booleanParam(
            name: 'CLEAN_BUILD',
            defaultValue: true,
            description: '체크 시 워크스페이스 완전 청소 (고객사 배포용 권장)'
        )
    }

    environment {
        // 호스트 측 공유 캐시 (실제 환경에서는 영속 디스크)
        DL_CACHE     = "/var/jenkins_cache/dl"
        CCACHE_DIR   = "/var/jenkins_cache/ccache"

        // 빌더 이미지 이름
        IMAGE_NAME   = "openwrt-ci-test-builder"
    }

    stages {
        stage('Checkout') {
            steps {
                script {
                    if (params.CLEAN_BUILD) {
                        cleanWs()
                    }
                }
                checkout scm
            }
        }

        stage('Prepare Cache Dirs') {
            steps {
                sh """
                    mkdir -p ${DL_CACHE} ${CCACHE_DIR}
                    echo "DL_CACHE  = ${DL_CACHE}"
                    echo "CCACHE_DIR = ${CCACHE_DIR}"
                """
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    // Dockerfile 해시로 태그 생성 → 변경 없으면 재사용
                    def dockerfileHash = sh(
                        script: 'sha256sum Dockerfile | cut -c1-12',
                        returnStdout: true
                    ).trim()

                    env.BUILDER_IMAGE = "${IMAGE_NAME}:${dockerfileHash}"
                    echo "Builder image: ${env.BUILDER_IMAGE}"

                    def exists = sh(
                        script: "docker image inspect ${env.BUILDER_IMAGE} > /dev/null 2>&1",
                        returnStatus: true
                    ) == 0

                    if (exists) {
                        echo "기존 이미지 재사용"
                    } else {
                        echo "이미지 새로 빌드"
                        sh """
                            docker build \\
                                --build-arg BUILD_UID=\$(id -u) \\
                                --build-arg BUILD_GID=\$(id -g) \\
                                -t ${env.BUILDER_IMAGE} .
                        """
                    }
                }
            }
        }

        stage('Configure') {
            steps {
                sh """
                    cp configs/${params.CUSTOMER}.config .config
                    cat .config
                """
            }
        }

        stage('Build in Container') {
            steps {
                script {
                    sh """
                        docker run --rm \\
                            -v ${WORKSPACE}:/src \\
                            -v ${DL_CACHE}:/src/dl \\
                            -v ${CCACHE_DIR}:/ccache \\
                            -e CCACHE_DIR=/ccache \\
                            -w /src \\
                            --user \$(id -u):\$(id -g) \\
                            ${env.BUILDER_IMAGE} \\
                            bash -c '
                                set -e
                                chmod +x scripts/*.sh
                                ./scripts/feeds.sh update -a
                                ./scripts/feeds.sh install -a
                                make defconfig
                                make -j\$(nproc)
                            '
                    """
                }
            }
        }

        stage('Verify Artifacts') {
            steps {
                sh """
                    echo "=== 산출물 확인 ==="
                    ls -lh bin/targets/${params.CUSTOMER}/
                    cat bin/targets/${params.CUSTOMER}/build-info.txt

                    echo ""
                    echo "=== 실행 시험 ==="
                    docker run --rm \\
                        -v ${WORKSPACE}:/src \\
                        -w /src \\
                        ${env.BUILDER_IMAGE} \\
                        ./bin/targets/${params.CUSTOMER}/app-* Jenkins
                """
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts(
                    artifacts: "bin/targets/${params.CUSTOMER}/**/*",
                    fingerprint: true
                )
            }
        }
    }

    post {
        success {
            echo "✅ 빌드 성공: ${params.CUSTOMER}"
        }
        failure {
            echo "❌ 빌드 실패"
        }
        always {
            // 컨테이너는 --rm 으로 이미 정리됨
            // 이미지는 캐시 위해 유지
            sh 'docker ps -a | head -5 || true'
        }
    }
}
