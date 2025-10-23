kubectl taint nodes imqa-database dedicated=database:NoSchedule
kubectl taint nodes imqa-collector dedicated=collector:NoSchedule
kubectl taint nodes imqa-web dedicated=api:NoSchedule
kubectl taint nodes imqa-symbolicator dedicated=symbolicator:NoSchedule
