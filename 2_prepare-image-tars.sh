#!/bin/bash

# 다운로드할 이미지 목록
IMAGES=(
  ### database
  "postgres:17.2-alpine3.21"
  "clickhouse/clickhouse-server:24.12.3.47-alpine"
  "clickhouse/clickhouse-keeper:24.12.3.47-alpine"

  ### spegel
  "ghcr.io/spegel-org/spegel:v0.4.0"

  ### openebs
  "openebs/lvm-driver:1.6.1"
  "registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.8.0"
  "registry.k8s.io/sig-storage/csi-provisioner:v3.5.0"
  "registry.k8s.io/sig-storage/csi-resizer:v1.8.0"
  "registry.k8s.io/sig-storage/csi-snapshotter:v6.2.2"
  "registry.k8s.io/sig-storage/snapshot-controller:v6.2.2"

  ### minio
  "quay.io/minio/mc:RELEASE.2024-11-21T17-21-54Z"
  "quay.io/minio/minio:RELEASE.2024-12-18T13-15-44Z"
)

# 결과 저장 폴더 생성
OUTPUT_DIR="image-tars"
mkdir -p $OUTPUT_DIR

echo "Docker 이미지 다운로드 및 .tar 파일 생성을 시작합니다."
echo "-----------------------------------------------------"

for IMAGE in "${IMAGES[@]}"; do
  echo "=> [1/2] '${IMAGE}' 이미지를 pull 합니다 (platform=linux/amd64)..."
  docker pull --platform=linux/amd64 "$IMAGE" || { echo "오류: '${IMAGE}' pull 실패"; continue; }

  # 파일 이름 변환 (/, : → _ 로 변경)
  SAFE_NAME=$(echo "$IMAGE" | tr '/:' '_')
  TAR_FILE="${OUTPUT_DIR}/${SAFE_NAME}.tar"

  echo "=> [2/2] '${IMAGE}' 이미지를 '${TAR_FILE}' 로 저장합니다..."
  docker save -o "$TAR_FILE" "$IMAGE" || { echo "오류: '${IMAGE}' 저장 실패"; continue; }

  echo "   -> 성공: ${SAFE_NAME}.tar"
done

echo "-----------------------------------------------------"
echo "✅ 모든 이미지 저장 작업이 완료되었습니다!"
echo "📁 생성된 폴더: ${OUTPUT_DIR}"

