#!/bin/bash

# =================================================================
# Docker 이미지를 pull 하고 .tar 파일로 저장하는 스크립트
# =================================================================

# 다운로드할 이미지 목록
IMAGES=(
  ### database
  "postgres:17.2-alpine3.21"
  "clickhouse/clickhouse-server:24.12.3.47-alpine"
  "clickhouse/clickhouse-keeper:24.12.3.47-alpine"

  ### spegel
  "ghcr.io/spegel-org/spegel:v0.4.0"

  ### openebs
  "openebs_lvm-driver_1.6.1.tar"
  "registry.k8s.io_sig-storage_csi-node-driver-registrar_v2.8.0.tar"
  "registry.k8s.io_sig-storage_csi-provisioner_v3.5.0.tar"
  "registry.k8s.io_sig-storage_csi-resizer_v1.8.0.tar"
  "registry.k8s.io_sig-storage_csi-snapshotter_v6.2.2.tar"
  "registry.k8s.io_sig-storage_snapshot-controller_v6.2.2.tar"

  ### minio
  "quay.io_minio_mc_RELEASE.2024-11-21T17-21-54Z.tar"
  "quay.io_minio_minio_RELEASE.2024-12-18T13-15-44Z.tar"
)

# 다운로드 받을 폴더 이름
DOWNLOAD_DIR="image-tars"

# --- 스크립트 시작 ---
echo "Docker 이미지 다운로드 및 .tar 파일 생성을 시작합니다."
echo "-----------------------------------------------------"

mkdir -p ${DOWNLOAD_DIR}

# 각 이미지에 대해 반복 작업
for IMAGE in "${IMAGES[@]}"; do
  # 파일 이름으로 사용하기 위해 이미지 이름의 '/'를 '_'로 변경
  TAR_FILENAME=$(echo ${IMAGE} | tr / _).tar
  
  echo "=> [1/2] '${IMAGE}' 이미지를 pull 합니다..."
  docker pull --platform linux/amd64 "${IMAGE}"
  if [ $? -ne 0 ]; then
      echo "오류: '${IMAGE}' pull에 실패했습니다."
      continue # 다음 이미지로 넘어감
  fi

  echo "=> [2/2] '${IMAGE}' 이미지를 '${DOWNLOAD_DIR}/${TAR_FILENAME}' 파일로 저장합니다..."
  docker save -o "${DOWNLOAD_DIR}/${TAR_FILENAME}" "${IMAGE}"
  if [ $? -ne 0 ]; then
      echo "오류: '${IMAGE}' 저장에 실패했습니다."
      continue # 다음 이미지로 넘어감
  fi
  echo "    -> 성공: ${TAR_FILENAME}"
done

echo "-----------------------------------------------------"
echo "✅ 모든 작업이 완료되었습니다!"
echo "생성된 폴더: ${DOWNLOAD_DIR}"
