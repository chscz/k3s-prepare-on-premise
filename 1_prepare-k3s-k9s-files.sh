#!/bin/bash

# =================================================================
# K3s 및 K9s 오프라인 설치 파일 준비 스크립트
# (Debian/Ubuntu 및 Red Hat/Rocky 계열 겸용)
# =================================================================

# --- 설정 변수 ---
K3S_VERSION="v1.33.4+k3s1"
DOWNLOAD_DIR="k3s-offline-bundle"

# --- 스크립트 시작 ---
echo "K3s 및 K9s 오프라인 설치 파일 다운로드를 시작합니다."
echo "대상 K3s 버전: ${K3S_VERSION}"
echo "-----------------------------------------------------"

# 다운로드 폴더 생성
mkdir -p "${DOWNLOAD_DIR}/for-redhat-rocky"
mkdir -p "${DOWNLOAD_DIR}/for-debian-ubuntu"
cd "${DOWNLOAD_DIR}"

# --- 공용 파일 다운로드 (모든 OS 필요) ---

echo "[1/4] K3s 바이너리 (공용) 다운로드 중..."
curl -sfL "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s" -o k3s

echo "[2/4] K3s 에어갭 이미지 (공용) 다운로드 중..."
curl -sfL "https://github.com/k3s-io/k3s/releases/download/${K3S_VERSION}/k3s-airgap-images-amd64.tar.gz" -o k3s-airgap-images-amd64.tar.gz

echo "[3/4] K9s 바이너리 (공용) 다운로드 중..."
curl -sL "https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_amd64.tar.gz" -o k9s_Linux_amd64.tar.gz

# --- OS 전용 파일 다운로드 ---

echo "[4/4] OS 전용 파일 다운로드 중..."
# Red Hat/Rocky 계열용
echo "    -> Red Hat/Rocky용 k3s-selinux RPM 다운로드..."
curl -sfL "https://rpm.rancher.io/k3s/stable/common/centos/9/noarch/k3s-selinux-1.6-1.el9.noarch.rpm" -o "for-redhat-rocky/k3s-selinux.rpm"

# Debian/Ubuntu 계열용 (AppArmor 관련) - K3s는 보통 추가 패키지 없이 잘 동작하지만, 종속성을 위해 apparmor-utils를 준비
echo "    -> Debian/Ubuntu용 apparmor-utils DEB 다운로드 준비 안내..."
# apparmor-utils는 OS 기본 저장소에 있으므로, 온라인 PC에서 아래 명령어로 .deb 파일만 별도로 다운받아 준비해야 합니다.
# sudo apt-get update && sudo apt-get install --download-only apparmor-utils
# 다운로드된 파일은 /var/cache/apt/archives/ 에 있습니다.
# 이 파일을 for-debian-ubuntu 폴더로 옮겨주세요.
touch "for-debian-ubuntu/apparmor-utils-deb-files-guide.txt"
echo "Debian/Ubuntu에 필요한 apparmor-utils.deb 파일은 온라인 PC에서 'sudo apt-get install --download-only apparmor-utils' 명령으로 다운로드한 뒤, /var/cache/apt/archives/ 경로에서 찾아 이 폴더로 옮겨주세요." > "for-debian-ubuntu/apparmor-utils-deb-files-guide.txt"


# --- 최종 안내 ---
echo "-----------------------------------------------------"
echo "✅ 모든 파일 다운로드 완료!"
echo "생성된 폴더: $(pwd)"
echo ""
echo "--- 다음 단계 안내 ---"
echo "1. 이 폴더(${DOWNLOAD_DIR}) 전체를 오프라인 서버로 옮기세요."
echo "2. Red Hat/Rocky 서버에는 공용 파일 3개와 'for-redhat-rocky' 폴더의 RPM을 사용하세요."
echo "3. Debian/Ubuntu 서버에는 공용 파일 3개만 기본으로 사용하며, 필요시 'for-debian-ubuntu' 폴더의 DEB 파일을 설치하세요."
