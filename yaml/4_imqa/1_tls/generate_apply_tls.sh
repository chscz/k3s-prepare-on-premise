openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
  -keyout server.key -out server.crt \
  -subj "/CN=IMQA Traefik Cert" \
  -addext "subjectAltName = IP:172.20.100.38,IP:223.130.160.178"

kubectl create secret tls web-tls \
  --cert=server.crt \
  --key=server.key \
  -n api
  