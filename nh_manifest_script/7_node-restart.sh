#!/bin/bash
## 이전 단계들에서 설정한 내용들을 적용하기 위한 서비스 재시작

# Detect node role and restart
if systemctl is-active --quiet k3s; then
    systemctl restart k3s
    echo "🔍 Successfully restart k3s"
elif systemctl is-active --quiet k3s-agent; then
    systemctl restart k3s-agent
    echo "🔍 Successfully restart k3s-agent"
else
    echo "❌ K3s is not running on this node. Exiting."
    exit 1
fi
