groupadd -f containerd

usermod -aG containerd "$SETUP_USER"

# /etc/systemd/system/k3s.service
# ExecStartPost=/bin/sh -c "sleep 5 && chgrp containerd /run/k3s/containerd/containerd.sock && chmod g+rw /run/k3s/containerd/containerd.sock"



chown -R ms어쩌고:users /etc/rancher/
chown -R ms어쩌고:users /var/lib/rancher
