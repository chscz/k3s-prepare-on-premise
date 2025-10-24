  # 🚀 k3s 폐쇄망 (Offline) 설치 및 구성 가이드

이 문서는 Git 저장소 내 스크립트와 파일을 이용하여 k3s 클러스터를 폐쇄망 환경에 설치하고 구성하는 절차를 안내합니다.

***

## I. 📦 사전 준비: 파일 및 이미지 확보 (외부망 환경)

설치에 필요한 모든 파일과 이미지를 외부망이 연결된 환경에서 미리 확보합니다.

| 파일/디렉토리 | 스크립트 | 설명 |
| :--- | :--- | :--- |
| **`k3s-offline-bundle/`** | `1_prepare-k3s-k9s-files.sh` | K3s 바이너리 및 필수 도구(k9s 등) 오프라인 번들 생성 |
| **`image-tars/`** | `2_prepare-image-tars.sh` | K3s 및 기본 Kubernetes 컴포넌트의 컨테이너 이미지를 tar 파일로 추출 |

> ⚠️ **주의:** **IMQA 이미지**와 같이 **Private Registry에 저장되어 로그인/인증이 필요한 이미지**는 스크립트가 자동으로 다운로드할 수 없으므로, **별도로 수동 다운로드 및 tar 파일로 준비**해야 합니다.

***

## II. 📤 파일 배포 및 환경 설정

### 1. 파일 복사 대상

1단계에서 준비된 파일과 기존 스크립트를 **설치 대상 서버**로 복사합니다.

| 노드 구분 | 복사 대상 파일 및 디렉토리 |
| :--- | :--- |
| **마스터 노드** | `k3s-offline-bundle/`, `image-tars/`, `3_install-offline.sh`, `4_setup-k3s-config.sh`, `5_setup-disk.sh`, `6_import-images.sh`, `7_node-restart.sh`, `8_taint.sh` |
| **워커 노드** | `k3s-offline-bundle/`, `3_install-offline.sh`, `4_setup-k3s-config.sh`, `5_setup-disk.sh`, `7_node-restart.sh` |

### 2. 계정 권한 설정

* **root 계정 사용 시:** 해당 과정 생략 가능.
* **일반 계정 사용 시:** 계정을 생성하고 **wheel 그룹**에 추가해야 합니다. (다른 그룹 사용 시 호환성 확인 필요)

***

## III. ⚙️ K3s 설치 및 구성 단계 (순서 필수)

### 1. K3s 오프라인 설치 (`3_install-offline.sh`) - 모든 노드 실행

설치는 **마스터 노드부터** 진행해야 합니다. 스크립트 실행 시 파라미터 없이 실행하면 필요 항목이 안내됩니다.

| 노드 구분 | 실행 예시 | 비고 |
| :--- | :--- | :--- |
| **마스터 노드** | `./3_install-offline.sh server` | - |
| **워커 노드** | `./3_install-offline.sh agent <MASTER-NODE-IP> <MASTER-NODE-TOKEN>` | **TOKEN**은 마스터 노드의 `/var/lib/rancher/k3s/server/token` 경로에서 확인 가능 |

### 2. K3s 기본 설정 파일 생성 (`4_setup-k3s-config.sh`) - 모든 노드 실행

| 노드 구분 | 생성 파일 |
| :--- | :--- |
| **마스터 노드** | `config.yaml`, `registry.yaml` |
| **워커 노드** | `registry.yaml` |

> 📌 **노드 이름 지정:** hostname 변경 없이 노드 이름을 지정하려면 각 노드의 `/etc/rancher/k3s/config.yaml` 파일 내에 `node-name: "<MY-NODE-NAME>"`을 추가하세요.

### 3. 디스크 설정 (`5_setup-disk.sh`) - 모든 노드 실행

OpenEBS LVM을 위한 볼륨 그룹을 설정합니다.

* **스크립트 내용 확인:** 사용할 볼륨이 이미 설정되어 있다면, 해당 스크립트의 내용을 **볼륨 관련 설정에 맞게 수정**하거나 필요한 명령어(`lvremove`, `pvcreate` 등)만 골라서 사용해야 합니다. (스크립트 내 주석 참고)
* **볼륨 그룹 변경:** 볼륨 그룹 이름(`openebs-vg`)을 변경하는 경우, 클러스터 배포 전 **`yaml/2_openebs/2_storageclass.yaml`** 내의 `parameters.volgroup` 값을 반드시 수정해야 합니다.

### 4. 이미지 Import (`6_import-images.sh`) - 마스터 노드만 실행

`image-tars/` 경로의 이미지 파일들을 k3s의 Containerd에 주입합니다.

> ✨ **P2P 이미지 공유:** 마스터 노드에서만 import해도 **spegel 기능**에 의해 **P2P 방식으로 노드 간 이미지가 공유**됩니다.

### 5. 서비스 재시작 (`7_node-restart.sh`) - 모든 노드 실행

이전 단계까지 설정한 내용들을 k3s 및 k3s-agent에 적용하기 위해 서비스를 재시작합니다.

### 6. Taint 설정 (`8_taint.sh`) - 마스터 노드만 실행

클러스터 운영 정책에 맞게 노드에 **taint**를 설정합니다. **각 노드의 구성에 맞게 스크립트 내용을 수정한 후** 사용하세요.

***

## IV. 🚀 Kubernetes Manifest 배포

### 1. Manifest 배포 순서

클러스터에 **`yaml/` 경로의 manifest**를 **파일 이름의 번호 순서**에 맞게 `kubectl apply -f` 명령으로 배포합니다.

### 2. 배포 전 필수 검토 및 수정 사항

| 항목 | 검토 및 수정 내용 |
| :--- | :--- |
| **노드 구성** | 노드 구성 및 설정한 taint에 맞게 Deployment 등의 manifest 파일 내 **`nodeSelector`** 및 **`toleration`**을 수정해야 합니다. |
| **리소스 설정** | 배포 대상의 필요 resource (`cpu`, `memory`, `storage`)를 확인하고, **노드 스펙**에 맞게 **`requests/limits`**를 수정해야 합니다. |
| **외부 연동** | `yaml/4_imqa/3_ingress/` 및 `yaml/4_imqa/2_secret/`의 tls 설정 등은 **배포 환경의 도메인 및 인증서**에 맞게 수정해야 합니다. |