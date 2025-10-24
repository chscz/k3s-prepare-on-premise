#!/bin/bash
## 마스터 노드: config.yaml / 워커 노드: config.yaml, registries.yaml 을 생성
# ===============================================
# setup-k3s-config.sh
# - Detects if the node is master or worker in K3s
# - Creates /etc/rancher/k3s/config.yaml and registries.yaml accordingly
# ===============================================

K3S_DIR="/etc/rancher/k3s"
CONFIG_FILE="${K3S_DIR}/config.yaml"
REGISTRY_FILE="${K3S_DIR}/registries.yaml"

# Ensure directory exists
sudo mkdir -p "$K3S_DIR"

# Detect node role
if systemctl is-active --quiet k3s; then
    NODE_ROLE="master"
elif systemctl is-active --quiet k3s-agent; then
    NODE_ROLE="worker"
else
    echo "❌ K3s is not running on this node. Exiting."
    exit 1
fi

echo "🔍 Detected node role: ${NODE_ROLE}"

# Create registries.yaml (common to both master and worker)
echo "📄 Creating ${REGISTRY_FILE}"
sudo tee "$REGISTRY_FILE" > /dev/null <<EOF
mirrors:
  "*": {}
EOF

# Create config.yaml (only for master node)
if [ "$NODE_ROLE" = "master" ]; then
    echo "📄 Creating ${CONFIG_FILE}"
    sudo tee "$CONFIG_FILE" > /dev/null <<EOF
embedded-registry: true
write-kubeconfig-mode: "0644"
EOF
else
    echo "⚙️ Worker node detected — skipping config.yaml creation."
fi

echo "✅ Configuration completed successfully."
echo "✅ /etc/rancher/k3s/config.yaml 파일에 노드이름 설정 필요"
echo '✅ config.yaml 의 최상위에  node-name: "<노드 이름>" 추가'
echo "✅ 노드이름은 사용하는 노드 수 또는 구성에 따라 임의로 지정하며 중복없어야 하고 모든 노드에 설정 권장"
