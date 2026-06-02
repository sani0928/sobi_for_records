#!/bin/bash
set -e

echo "🚀 AIoT 스마트바스켓 EC2 초기화 스크립트 시작"

echo "1️⃣ 시스템 패키지 업데이트 및 필수 도구 설치"
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y git docker.io docker-compose

echo "2️⃣ 현재 사용자에 docker 그룹 권한 부여"
sudo usermod -aG docker $USER
newgrp docker

echo "3️⃣ 프로젝트 클론 또는 진입"
# 이미 복제되어 있다면 생략 (없을 경우만 클론)
if [ ! -d "S13P11B103" ]; then
    git clone https://your.git.repo/S13P11B103.git
fi
cd S13P11B103

echo "4️⃣ .env 및 인증서 준비 확인 (수동 준비 필요)"
if [ ! -f ".env" ]; then
    echo "❗ .env 파일이 누락되었습니다. secrets 폴더 등에서 복사해주세요."
    exit 1
fi

echo "5️⃣ 도커 컴포즈로 핵심 인프라 구동 (core / jenkins / monitoring)"
docker compose -f docker-compose.core.yaml up -d
docker compose -f docker-compose.jenkins.yaml up -d
docker compose -f docker-compose.monitoring.yaml up -d

echo "6️⃣ web 서비스는 Jenkins에서 자동으로 구동됩니다."
echo "   ➤ 만약 GitLab 연동이 불가하거나 Jenkins 사용이 어려우면 아래 명령어로 수동 실행하세요:"
echo "       docker compose -f docker-compose.web.yaml up -d"

echo "7️⃣ AI 모델 파이프라인(MLOps) 구동: ai 디렉토리로 이동 후 실행"
cd ai
docker compose -f docker-compose.mlops.yaml up -d
cd ..

echo "✅ 모든 서비스 준비 완료!"
echo "📌 확인 포인트:"
echo "   - Jenkins: http://<EC2-IP>:8080"
echo "   - Grafana: http://<EC2-IP>:3001"
echo "   - Nginx (서비스 진입점): http://<도메인 또는 EC2-IP>"
