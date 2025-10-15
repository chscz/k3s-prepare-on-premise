#!/bin/bash

# =================================================================
# K3s 및 K9s 오프라인 설치 및 설정 스크립트
# OS를 자동 감지하여 Rocky(RHEL) 또는 Debian(Ubuntu)에 맞게 설치
# =================================================================

set -e # 오류 발생 시 즉시 스크립트 중단

# --- 변수 및 함수 정의 ---
FILES_DIR="k3s-offline-bundle"

# OS 확인 함수
detect_os() {
  if [ -f /etc/redhat-release ]; then
    OS_FAMILY="redhat"
  elif [ -f /etc/debian_version ]; then
    OS_FAMILY="debian"
  else
    echo "오류: 지원하지 않는 OS입니다. Red Hat/Rocky 또는 Debian/Ubuntu 계열에서 실행해주세요."
    exit 1
  fi
}

# --- 메인 스크립트 시작 ---

# 0. 스크립트 사용법 확인
if [ "$#" -eq 0 ]; then
  echo "사용법: "
  echo "  마스터 노드 설치: $0 server"
  echo "  워커 노드 설치:   $0 agent <마스터_사설IP> <조인_토큰>"
  exit 1
fi

# 1. OS 감지
detect_os
echo "감지된 OS 계열: ${OS_FAMILY}"
echo "-----------------------------------------------------"

# 2. 파일 존재 여부 확인
if [ ! -d "${FILES_DIR}" ]; then
  echo "오류: '${FILES_DIR}' 디렉터리를 찾을 수 없습니다."
  echo "이 스크립트는 '${FILES_DIR}' 폴더와 같은 위치에서 실행해야 합니다."
  exit 1
fi

# 3. OS별 사전 작업
echo "OS별 사전 작업을 시작합니다..."
if [ "${OS_FAMILY}" == "redhat" ]; then
  echo "-> Rocky/RHEL: k3s-selinux.rpm 설치 중..."
  sudo yum localinstall -y "${FILES_DIR}/for-redhat-rocky/k3s-selinux.rpm"
elif [ "${OS_FAMILY}" == "debian" ]; then
  echo "-> Debian/Ubuntu: 추가 작업이 필요 없습니다."
fi

# 4. K3s 및 K9s 공용 파일 설치
echo "공용 파일 설치를 시작합니다..."
sudo cp "${FILES_DIR}/k3s" /usr/local/bin/k3s && sudo chmod +x /usr/local/bin/k3s
sudo mkdir -p /var/lib/rancher/k3s/agent/images/
sudo cp "${FILES_DIR}/k3s-airgap-images-amd64.tar.gz" /var/lib/rancher/k3s/agent/images/
tar -xvf "${FILES_DIR}/k9s_Linux_amd64.tar.gz" -C ./ && sudo mv ./k9s /usr/local/bin/k9s

# 5. K3s 역할(server/agent)에 따라 설치 실행
ROLE=$1

# 설정 파일이 위치할 디렉터리 미리 생성
sudo mkdir -p /etc/rancher/k3s/

if [ "${ROLE}" == "server" ]; then
  echo "-----------------------------------------------------"
  echo "🚀 K3s 서버(마스터) 노드 설치를 시작합니다..."
  echo "-> 설정 파일(config.yaml, registries.yaml)을 생성합니다."
  sudo bash -c 'cat <<EOF > /etc/rancher/k3s/config.yaml
embedded-registry: true
write-kubeconfig-mode: "0644"
EOF'
  sudo bash -c 'cat <<EOF > /etc/rancher/k3s/registries.yaml
mirrors:
  "*": {}
EOF'

  # K3s 서버 설치
  curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_DOWNLOAD=true sh -

  # --- [수정된 부분] Kubeconfig 파일을 표준 위치로 복사 ---
  echo "-> kubectl 및 k9s 사용을 위한 설정을 구성합니다..."
  
  setup_user_config() {
    local user_home=$1
    local user_name=$(basename "${user_home}")

    if [ -d "${user_home}" ]; then
      # Kubeconfig 설정
      sudo mkdir -p "${user_home}/.kube"
      sudo cp /etc/rancher/k3s/k3s.yaml "${user_home}/.kube/config"
      sudo chown -R $(id -u ${user_name}):$(id -g ${user_name}) "${user_home}/.kube"
      echo "   - ${user_home}/.kube/config 파일 생성 완료"
    fi
  }

  # root 사용자 및 sudo 사용자 홈 디렉터리에 적용
  setup_user_config "/root"
  SUDO_USER=$(logname 2>/dev/null || echo ${SUDO_USER})
  if [ -n "${SUDO_USER}" ] && [ "${SUDO_USER}" != "root" ]; then
      USER_HOME=$(eval echo ~${SUDO_USER})
      setup_user_config "${USER_HOME}"
  fi
  # --- [수정된 부분 끝] ---
  
  echo "✅ K3s 서버 설치 및 설정 완료!"
  echo "이제 바로 'k9s' 또는 'kubectl' 명령어를 사용할 수 있습니다."
  echo ""
  echo "아래 토큰을 복사하여 워커 노드 설치 시 사용하세요:"
  sudo cat /var/lib/rancher/k3s/server/node-token

elif [ "${ROLE}" == "agent" ]; then
  if [ "$#" -ne 3 ]; then
    echo "오류: 워커 노드 설치 시에는 마스터 IP와 토큰이 필요합니다."
    echo "사용법: $0 agent <마스터_사설IP> <조인_토큰>"
    exit 1
  fi
  MASTER_IP=$2
  NODE_TOKEN=$3
  echo "-----------------------------------------------------"
  echo "💪 K3s 에이전트(워커) 노드 설치를 시작합니다..."
  echo "-> 설정 파일(registries.yaml)을 생성합니다."
  sudo bash -c 'cat <<EOF > /etc/rancher/k3s/registries.yaml
mirrors:
  "*": {}
EOF'

  # K3s 에이전트 설치
  curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL="https://""${MASTER_IP}"":6443" K3S_TOKEN="${NODE_TOKEN}" sh -
  
  echo "✅ K3s 에이전트 설치 완료!"

else
  echo "오류: 알 수 없는 역할입니다. 'server' 또는 'agent'를 선택하세요."
  exit 1
fi
