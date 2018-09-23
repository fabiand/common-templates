#cloud-config

password: centos
chpasswd: {expire: False}
ssh_pwauth: True
ssh_authorized_keys:
  - $PUBKEY

package_upgrade: false

runcmd:
- |
  KUBERNETES_VER=v1.11.2
  KUBEVIRT_VER=v0.8.0-alpha.0
  
  PATH=$PATH:/usr/local/bin
  
  set -x

  hostnamectl set-hostname minikube

  # from https://kubernetes.io/docs/setup/independent/install-kubeadm/
  yum install -y docker
  systemctl enable docker && systemctl start docker
  
  cat <<EOF > /etc/yum.repos.d/kubernetes.repo
  [kubernetes]
  name=Kubernetes
  baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
  enabled=1
  gpgcheck=1
  repo_gpgcheck=1
  gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
  exclude=kube*
  EOF
  setenforce 0
  yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
  systemctl enable kubelet && systemctl start kubelet
  
  cat <<EOF >  /etc/sysctl.d/k8s.conf
  net.bridge.bridge-nf-call-ip6tables = 1
  net.bridge.bridge-nf-call-iptables = 1
  EOF
  sysctl --system
  
  kubeadm init --pod-network-cidr=10.244.0.0/16

  mkdir -p ~/.kube
  sudo cat /etc/kubernetes/admin.conf > ~/.kube/config
  kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml

  kubectl create configmap -n kube-system kubevirt-config --from-literal debug.useEmulation=true || true
  kubectl apply -f https://github.com/kubevirt/kubevirt/releases/download/$KUBEVIRT_VER/kubevirt.yaml
