## openebs가 사용되는 모든 노드에서 실행해야 함
###############################################
## 완전 초기화: 논리 볼륨 - 볼륨 그룹 - 물리 볼륨 - 디스크 서명 순으로 모두 제거
## - 논리 볼륨 삭제
## sudo lvremove -f openebs-vg/pvc-2c4c0b8e-a20f-4c07-b8b6-d3902e1f0a13
## - openebs-vg 볼륨 그룹을 강제로 삭제
## sudo vgremove -f openebs-vg
## - 물리 볼륨 제거
## sudo pvremove /dev/vdb
## - 디스크 서명 제거 (이전 단계에서 이미 했다면 건너뛰어도 됨)
## sudo wipefs -a /dev/vdb
## - 확인
## lsblk
## vgs
sudo pvcreate /dev/vdb
sudo vgcreate openebs-vg /dev/vdb
sudo vgdisplay openebs-vg
