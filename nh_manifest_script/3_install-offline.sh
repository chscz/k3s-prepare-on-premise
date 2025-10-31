#!/bin/bash
# =================================================================
# 🧱 K3s 및 K9s 완전 오프라인 설치 스크립트 (공식 get.k3s.io 기반)
# OS 자동 감지 및 embedded-registry / airgap 이미지 설정 포함
# =================================================================

set -euo pipefail

FILES_DIR="k3s-offline-bundle"

# --- OS 감지 ---
detect_os() {
  if [ -f /etc/redhat-release ]; then
    OS_FAMILY="redhat"
  elif [ -f /etc/debian_version ]; then
    OS_FAMILY="debian"
  else
    echo "❌ 지원되지 않는 OS입니다. Rocky(RHEL) 또는 Debian/Ubuntu 계열에서 실행해주세요."
    exit 1
  fi
}

# --- 심볼릭 링크 생성 ---
create_symlinks() {
  echo "🔗 K3s 관련 심볼릭 링크 생성..."
  for cmd in kubectl crictl ctr; do
    if [ ! -e "/usr/local/bin/${cmd}" ]; then
      sudo ln -sf /usr/local/bin/k3s "/usr/local/bin/${cmd}"
    fi
  done
}

# --- killall / uninstall 스크립트 생성 ---
create_aux_scripts() {
  echo "🧩 killall 및 uninstall 스크립트 생성..."
  cat <<'EOF' | sudo tee /usr/local/bin/k3s-killall.sh >/dev/null
#!/bin/sh
set -x
for svc in /etc/systemd/system/k3s*.service; do
  [ -s "$svc" ] && systemctl stop $(basename "$svc")
done
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete flannel-wg 2>/dev/null || true
rm -rf /var/lib/cni /run/flannel /run/k3s /var/lib/kubelet
iptables-save | grep -v KUBE- | grep -v CNI- | iptables-restore
EOF

  cat <<'EOF' | sudo tee /usr/local/bin/k3s-uninstall.sh >/dev/null
#!/bin/sh
set -x
systemctl stop k3s
systemctl disable k3s
rm -f /etc/systemd/system/k3s.service
rm -rf /usr/local/bin/k3s /usr/local/bin/kubectl /usr/local/bin/crictl /usr/local/bin/ctr
rm -rf /etc/rancher /var/lib/rancher /var/lib/kubelet /run/k3s
systemctl daemon-reload
echo "✅ K3s 제거 완료"
EOF

  sudo chmod +x /usr/local/bin/k3s-killall.sh /usr/local/bin/k3s-uninstall.sh
}

# --- systemd 서비스 파일 생성 ---
create_systemd_unit() {
  local role=$1
  local exec_cmd

  if [ "$role" == "server" ]; then
    exec_cmd="/usr/local/bin/k3s server --config /etc/rancher/k3s/config.yaml"
  else
    exec_cmd="/usr/local/bin/k3s agent --config /etc/rancher/k3s/config.yaml"
  fi

  echo "🧠 systemd 유닛 생성..."
  sudo tee /etc/systemd/system/k3s.service >/dev/null <<EOF
[Unit]
Description=Lightweight Kubernetes (K3s)
Documentation=https://k3s.io
Wants=network-online.target
After=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
Type=notify
EnvironmentFile=-/etc/default/%N
EnvironmentFile=-/etc/sysconfig/%N
KillMode=process
Delegate=yes
User=root
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Restart=always
RestartSec=5s
ExecStartPre=-/sbin/modprobe br_netfilter
ExecStartPre=-/sbin/modprobe overlay
ExecStart=${exec_cmd}
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now k3s
}

# --- kubeconfig 복사 ---
setup_kubeconfig() {
  local home_dir=$1
  if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    sudo mkdir -p "${home_dir}/.kube"
    sudo cp /etc/rancher/k3s/k3s.yaml "${home_dir}/.kube/config"
    sudo chown -R $(id -u $(basename "${home_dir}")):$(id -g $(basename "${home_dir}")) "${home_dir}/.kube"
    echo "   ✅ ${home_dir}/.kube/config 생성 완료"
  fi
}

# --- 메인 실행 ---
if [ $# -lt 1 ]; then
  echo "사용법:"
  echo "  서버 설치: $0 server"
  echo "  워커 설치: $0 agent <MASTER_IP> <NODE_TOKEN>"
  exit 1
fi

ROLE=$1
detect_os
echo "감지된 OS 계열: ${OS_FAMILY}"
echo "-----------------------------------------------------"

# --- 파일 확인 ---
if [ ! -d "${FILES_DIR}" ]; then
  echo "❌ '${FILES_DIR}' 폴더를 찾을 수 없습니다."
  exit 1
fi

# --- 사전작업 ---
if [ "${OS_FAMILY}" == "redhat" ]; then
  echo "📦 SELinux 정책 설치 중..."
  sudo yum localinstall -y "${FILES_DIR}/for-redhat-rocky/k3s-selinux.rpm"
fi

# --- 공용 파일 설치 ---
echo "📂 K3s 및 K9s 설치 중..."
sudo cp "${FILES_DIR}/k3s" /usr/local/bin/k3s
sudo chmod +x /usr/local/bin/k3s
sudo mkdir -p /var/lib/rancher/k3s/agent/images
sudo cp "${FILES_DIR}/k3s-airgap-images-amd64.tar.gz" /var/lib/rancher/k3s/agent/images/
tar -xzf "${FILES_DIR}/k9s_Linux_amd64.tar.gz" -C ./ >/dev/null 2>&1 || true
sudo mv -f ./k9s /usr/local/bin/k9s 2>/dev/null || true
sudo chmod +x /usr/local/bin/k9s

create_symlinks
create_aux_scripts
sudo mkdir -p /etc/rancher/k3s

# --- 노드 이름 입력 ---
read -rp "🖥️  노드 이름을 입력하세요 (예: master-01 또는 worker-01): " NODE_NAME
if [ -z "${NODE_NAME}" ]; then
  echo "❌ 노드 이름은 반드시 입력해야 합니다."
  exit 1
fi

# --- 역할별 처리 ---
if [ "$ROLE" == "server" ]; then
  echo "-----------------------------------------------------"
  echo "🚀 K3s 서버(마스터) 설치 시작..."

  sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
node-name: ${NODE_NAME}
embedded-registry: true
write-kubeconfig-mode: "0644"
disable:
  - traefik
  - servicelb
EOF

  sudo tee /etc/rancher/k3s/registries.yaml >/dev/null <<EOF
mirrors:
  "*": {}
EOF

  create_systemd_unit "server"

  echo "⏳ K3s 서버 기동 중... (30초 대기)"
  sleep 30

  setup_kubeconfig "/root"
  if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    setup_kubeconfig "$(eval echo ~${SUDO_USER})"
  fi

  echo "✅ K3s 서버 설치 완료!"
  echo "🔑 워커 조인 토큰:"
  sudo cat /var/lib/rancher/k3s/server/node-token || echo "(아직 생성 중입니다.)"

elif [ "$ROLE" == "agent" ]; then
  if [ $# -ne 3 ]; then
    echo "❌ 사용법: $0 agent <MASTER_IP> <NODE_TOKEN>"
    exit 1
  fi
  MASTER_IP=$2
  NODE_TOKEN=$3

  echo "-----------------------------------------------------"
  echo "💪 K3s 워커(에이전트) 설치 시작..."

  sudo tee /etc/rancher/k3s/config.yaml >/dev/null <<EOF
node-name: ${NODE_NAME}
server: https://${MASTER_IP}:6443
token: ${NODE_TOKEN}
EOF

  sudo tee /etc/rancher/k3s/registries.yaml >/dev/null <<EOF
mirrors:
  "*": {}
EOF

  create_systemd_unit "agent"

  echo "✅ K3s 에이전트 설치 완료!"
else
  echo "❌ 오류: 역할은 'server' 또는 'agent'만 가능합니다."
  exit 1
fi

echo "-----------------------------------------------------"
echo "🎉 설치 완료!"
echo " - 서비스 확인: sudo systemctl status k3s"
echo " - 로그 확인:   sudo journalctl -u k3s -f"
echo "-----------------------------------------------------"
