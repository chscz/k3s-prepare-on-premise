## openebs가 사용되는 모든 노드에서 실행해야 함
sudo pvcreate /dev/vdb
sudo vgcreate openebs-vg /dev/vdb
sudo vgdisplay openebs-vg

