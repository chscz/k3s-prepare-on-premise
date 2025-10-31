## 실행 전 노드 개수 등 배포 구성에 맞게 수정 후 실행
# kubectl taint nodes imqa-database dedicated=database:NoSchedule
# kubectl taint nodes imqa-collector dedicated=collector:NoSchedule
# kubectl taint nodes imqa-web dedicated=api:NoSchedule
# kubectl taint nodes imqa-symbolicator dedicated=symbolicator:NoSchedule
