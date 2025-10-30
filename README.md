### check
- `node taint`
- `node count`, `node name`
- `k3s config.yaml`
- `volume group`, `physical volume`, `logical volume`
- `daemonset`, `deployment`, `statefulset` >> `nodeSelector`, `toleration`
- `ttl setting`, `ingress setting`
- `dns`, `url`, `host`, `ip`
- `postgres migrate`
---
### 1. 외부망이 되는 환경에서 `1_prepare-k3s-k9s-files.sh`, `2_prepare-image-tars.sh` 를 실행하여 파일 준비
  - `1_prepare-k3s-k9s-files.sh` 실행시 해당 경로에 `k3s-offline-bundle` 디렉토리 생성됨
  - `2_prepare-image-tars.sh` 실행시 해당 경로에 `image-tars` 디렉토리 생성됨
  - imqa 이미지와 같이 private registry 에 저장되어 로그인 또는 인증이 필요한 이미지들은 별도 준비
---
### 2. 기존 파일 및 디렉토리와 1번 과정에서 생성된 파일 및 디렉토리를 설치 대상 서버로 파일 복사
  - 마스터노드:
    - k3s-offline-bundle/
    - image-tars/
    - 3_install-offline.sh
    - 4_setup-k3s-config.sh
    - 5_setup-disk.sh
    - 6_import-images.sh
    - 7_node-restart.sh
    - 8_taint.sh
  - 워커노드
    - k3s-offline-bundle
    - 3_install-offline.sh
    - 4_setup-k3s-config.sh
    - 5_setup-disk.sh
    - 7_node-restart.sh
---
### 3. 계정 생성 및 wheel 그룹에 추가(root 사용시 해당 과정 생략)
  - wheel 그룹이 아닌 일반 계정을 사용할 경우 나도 모름 안해봄
---
### 4. `3_install-offline.sh` - 모든 노드 실행
  - 파라미터 없이 스크립트 실행시 필요 항목 안내 나옴
  - 마스터노드부터 설치해야 함(워커노드 설치시 마스터노드의 IP와 설치 완료 후 생성되는 TOKEN이 필요)
  - 토큰을 확인 못한 경우 마스터노드의 `/var/lib/rancher/k3s/server/token` 경로에 토큰 확인
  - 실행 예시(마스터노드)
  - `./3_install-offline.sh server`
  - 실행 예시(워커노드)
  - `./3_install-offline.sh agent <MASTER-NODE-IP> <MASTER-NODE-TOKEN>`
---
### 5. `4_setup-k3s-config.sh` - 모든 노드 실행
  - 생성파일
  -- 마스터노드: `config.yaml`, `registry.yaml`
  -- 워커노드: `registry.yaml`
  - 노드의 이름은 기본적으로 서버의 `hostname` 이 사용되며, hostname 변경없이 노드이름을 지정하고 싶은 경우 각 노드의 `/etc/rancher/k3s/config.yaml` 파일 내에 `node-name: "<MY-NODE-NAME>"` 을 추가
---
### 6. `5_setup-disk.sh` - 모든 노드 실행
  - 사용할 볼륨이 아무것도 설정되어 있지 않은 초기 상태면 해당 스크립트 실행시 바로 완료가 되지만
    이미 설정되어 있는 항목들이 있다면 그에 맞게 볼륨 관련 설정을 변경하거나 해당 스크립트의 내용을 수정해서 사용하거나
    필요한 명령어만 골라서 사용해야 함
  - 논리 볼륨, 물리 볼륨, 볼륨 그룹 등 필요한 명령어는 스크립트 내의 주석 확인
  - 볼륨 그룹의 스크립트 내에 설정된 `openebs-vg` 가 아닌 다른 값을 사용할 경우
    `yaml/2_openebs/2_storageclass.yaml` 내의 `parameters.volgroup` 값을 변경해줘야 함
---
### 7. `6_import-images.sh` - 마스터 노드 실행
  - `image-tars/` 경로의 이미지 파일들을 k3s에 import
  - 마스터노드에서만 import해도 `spegel` 에 의해 p2p 방식으로 노드 간 이미지가 공유됨
---
### 8. `7_node-restart.sh` - 모든 노드 실행
  - 이전 단계까지 설정한 내용들을 `k3s`와 `k3s-agent`에 적용하기 위한 서비스 재시작
---
### 9. `8_taint.sh` - 마스터 노드 실행
  - 각 노드의 taint 설정으로 노드 구성에 맞게 수정 후 사용
---
### 10. 클러스터에 `yaml/` 경로의 `manifest`를 `번호 순서`에 맞게 배포
  - 배포 전 노드 구성 및 설정한 `taint` 에 맞게 `nodeSelector`, `toleration` 을 수정 후 배포
  - 배포 전 배포 대상의 필요 `resource(cpu, memory, storage)` 를 확인하고 노드 스펙에 맞게 수정
  - `yaml/4_imqa/3_ingress/` , `yaml/4_imqa/2_secret/ 의 tls` 등은 배포 환경에 맞게 수정
  
