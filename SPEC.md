## 본 내용은 NH BANK 기준으로 작성하였습니다.
## k3s 설치 및 클러스터 구성시 root 영역(VG_OS)에 설치/운영이 필요하며, kubernetes 내부에서 실행되는 앱들이 직접적으로 사용하는 볼륨은 VG_APP 그룹을 사용합니다.
## VG_APP 의 타입은 반드시 LVM 이어야 합니다.
## 안정적인 운영에 초점을 두어 여유있게 산정하였으나, 실 운영 단계의 상황에 따라 다소 조정이 필요할 수 있습니다.


## k3s 클러스터 구성시 생성 파일/디렉토리

[ 파일 생성 ]
/usr/local/bin/k3s                      # k3s의 단일 실행 바이너리 파일
/usr/local/bin/kubectl                  # k8s 클러스터 관리 공식 CLI 파일
/usr/local/bin/crictl                   # CRI 컨테이너 런타임 인터페이스 CLI 파일
/usr/local/bin/ctr                      # containerd 컨테이너 런타임, 이미지 관리 CLI 파일
/usr/local/bin/k9s                      # k8s 관리용 TUI 파일
/usr/local/bin/k3s-uninstall.sh         # k3s 클러스터 컴포넌트 중지/제거 스크립트 파일
/usr/local/bin/k3s-killall.sh           # k3s 및 관련 프로세스 강제 종료 스크립트 파일
/etc/systemd/system/k3s.service         # k3s 서버(마스터) 역할을 위한 systemd 서비스 유닛 파일
/etc/systemd/system/k3s-agent.service   # k3s 에이전트(워커) 역할을 위한 systemd 서비스 유닛 파일

[ 디렉토리 생성 ]
/etc/rancher/   # k3s의 핵심 설정 디렉토리

/var/lib/rancher/   # k3s 데이터 디렉토리
/var/lib/kubelet/   # kubelet의 볼륨 마운트, 체크포인트 등 노드별 데이터 관리 디렉토리
/var/lib/cni/       # CNI (Container Network Interface) 플러그인 설정 및 상태 정보 디렉토리

/run/k3s/       # k3s 프로세스 실행 중 생성되는 임시 상태 파일(PID, 소켓) 관리 디렉토리
/run/flannel/   # flannel CNI 네트워크 상태 정보를 임시로 저장하는 디렉터리

/var/log/pods/         # 쿠버네티스 파드(pod) 로그의 실제 저장 디렉토리
/var/log/containers/   # 컨테이너 로그 파일에 대한 심볼릭 링크 디렉토리


## 운영계  ─────────────────────────────────────────────
[ Proxy ] - 1TB

[ Web ](Master Node) - 1TB
VG_OS  : 400GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (250GB)
   ├─ /var/lib/kubelet/ (5GB)
   ├─ /var/lib/cni/ (500MB)
   ├─ /run/k3s/ (500MB)
   ├─ /var/flannel/ (500MB)
   ├─ /var/log/pods (60GB)
   ├─ /var/log/containers (30GB)
   └─ 기타 나머지 여유 공간
VG_APP : 600GB

[ Collector ](Worker Node) - 512GB
VG_OS  : 200GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (80GB)
   ├─ /var/lib/kubelet/ (5GB)
   ├─ /var/lib/cni/ (500MB)
   ├─ /run/k3s/ (500MB)
   ├─ /var/flannel/ (500MB)
   ├─ /var/log/pods (40GB)
   ├─ /var/log/containers (20GB)
   └─ 기타 나머지 여유 공간
VG_APP : 312GB

[ Symbolicator ](Worker Node) - 512GB
VG_OS  : 200GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (80GB)
   ├─ /var/lib/kubelet/ (5GB)
   ├─ /var/lib/cni/ (500MB)
   ├─ /run/k3s/ (500MB)
   ├─ /var/flannel/ (500MB)
   ├─ /var/log/pods (40GB)
   ├─ /var/log/containers (20GB)
   └─ 기타 나머지 여유 공간
VG_APP : 312GB

[ Database ](Worker Node) - 10TB
VG_OS  : 200GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (80GB)
   ├─ /var/lib/kubelet/ (5GB)
   ├─ /var/lib/cni/ (500MB)
   ├─ /run/k3s/ (500MB)
   ├─ /var/flannel/ (500MB)
   ├─ /var/log/pods (40GB)
   ├─ /var/log/containers (20GB)
   └─ 기타 나머지 여유 공간
VG_APP : 9.8TB
──────────────────────────────────────────────────────

## 개발계  ─────────────────────────────────────────────
[ Proxy ] - 512GB

[ Web / Collector / Symbolicator ](Master Node) - 512GB
VG_OS  : 200GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (80GB)
   ├─ /var/lib/kubelet (5GB)
   ├─ /var/lib/cni (500MB)
   ├─ /run/k3s (500MB)
   ├─ /run/flannel (500MB)
   ├─ /var/log/pods (40GB)
   ├─ /var/log/containers (20GB)
   └─ 기타 나머지 여유 공간
VG_APP : 312GB

[ Database ](Worker Node) - 1TB
VG_OS  : 150GB
   ├─ /usr/local/bin/ (1GB)
   ├─ /etc/rancher/ (500MB)
   ├─ /var/lib/rancher/ (30GB)
   ├─ /var/lib/kubelet (5GB)
   ├─ /var/lib/cni (500MB)
   ├─ /run/k3s (500MB)
   ├─ /run/flannel (500MB)
   ├─ /var/log/pods (40GB)
   ├─ /var/log/containers (20GB)
   └─ 기타 나머지 여유 공간
VG_APP : 850GB
──────────────────────────────────────────────────────
