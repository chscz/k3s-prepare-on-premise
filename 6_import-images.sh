#!/bin/bash

# =================================================================
# 'image-tars' 디렉터리의 모든 .tar 이미지를 K3s로 임포트하는 스크립트
# 실패한 이미지 리스트를 마지막에 출력
# =================================================================

IMAGE_DIR="image-tars"
K3S_CMD="/usr/local/bin/k3s" # k3s 명령어 전체 경로 지정

# 실패 기록용 배열
IMPORT_FAILED=()

# 1. K3s 명령어 존재 여부 확인
if [ ! -f "${K3S_CMD}" ]; then
  echo "오류: K3s 명령어(${K3S_CMD})를 찾을 수 없습니다."
  exit 1
fi

# 2. 디렉터리 존재 여부 확인
if [ ! -d "${IMAGE_DIR}" ]; then
  echo "오류: '${IMAGE_DIR}' 디렉터리를 찾을 수 없습니다."
  echo "이 스크립트는 '${IMAGE_DIR}' 폴더와 같은 위치에서 실행해야 합니다."
  exit 1
fi

# 3. .tar 파일 존재 여부 확인
if ! ls ${IMAGE_DIR}/*.tar &> /dev/null; then
  echo "알림: '${IMAGE_DIR}' 디렉터리에 임포트할 .tar 파일이 없습니다."
  exit 0
fi

echo "이미지 임포트를 시작합니다..."
echo "-----------------------------------------------------"

# 4. 각 .tar 파일에 대해 반복 작업
for image_file in ${IMAGE_DIR}/*.tar; do
  echo "=> 임포트 중: ${image_file}"
  if ! sudo ${K3S_CMD} ctr images import "${image_file}"; then
    echo "   ❌ 오류: '${image_file}' 임포트 실패"
    IMPORT_FAILED+=("${image_file}")
    continue
  fi
  echo "   ✅ 성공: ${image_file} 임포트 완료"
done

echo "-----------------------------------------------------"

# 5. 실패 결과 요약
if [ ${#IMPORT_FAILED[@]} -ne 0 ]; then
  echo "⚠️ 일부 이미지 임포트 실패:"
  for img in "${IMPORT_FAILED[@]}"; do
    echo "   - ${img}"
  done
else
  echo "✅ 모든 이미지 임포트 성공!"
fi
