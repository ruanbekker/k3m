#!/usr/bin/env bash

# is multipass installed?
which multipass  &> /dev/null && MULTIPASS_EXIT_CODE=${?} || MULTIPASS_EXIT_CODE=${?}
if [ "${MULTIPASS_EXIT_CODE}" == 1 ]
then
  echo ""
  echo "Multipass is not installed:"
  echo "-> https://multipass.run/docs"
  echo ""
  echo "Linux:   sudo snap install multipass --classic"
  echo "MacOS:   brew cask install multipass"
  echo "Windows: choco install multipass"
  echo ""
  exit 1
fi

# global environment variables
K3M_PATH=~/.k3m
K3M_INSTANCE_IMAGE="bionic"
K3M_INSTANCE_NAME="k3s"
K3M_CLOUD_INIT="cloud-init-k3s.yml"
K3M_SSH_PRIVATE_KEY=~/.ssh/id_rsa
K3M_SSH_PUBLIC_KEY=${K3M_SSH_PRIVATE_KEY}.pub

# create k3m home directory
mkdir -p ${K3M_PATH}

# check if specified public key exists
if [ -f "${K3M_SSH_PUBLIC_KEY}" ]
  then
    # key exists, read content
    K3M_SSH_PUBLIC_KEY_CONTENT="$(cat ${K3M_SSH_PUBLIC_KEY})"

  else 
    # key does not exist, create key
    echo "Specified key does not exist, creating ssh key ~/.k3m/ssh_key"
    ssh-keygen -b 2048 -f ${K3M_PATH}/ssh_key -t rsa -C "k3m" -q -N ""
    K3M_SSH_PRIVATE_KEY=${K3M_PATH}/ssh_key
    K3M_SSH_PUBLIC_KEY=${K3M_SSH_PRIVATE_KEY}.pub
    K3M_SSH_PUBLIC_KEY_CONTENT="$(cat ${K3M_SSH_PUBLIC_KEY})"
fi

# generate cloud-config
cat > ${K3M_PATH}/${K3M_CLOUD_INIT} << EOF
#cloud-config
ssh_authorized_keys:
  - ${K3M_SSH_PUBLIC_KEY_CONTENT}

package_update: true
packages:
 - curl

runcmd:
- curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" sh -s -
EOF

# deploy multipass instance with generated cloud-config
multipass launch ${K3M_INSTANCE_IMAGE} --name ${K3M_INSTANCE_NAME} --cloud-init ${K3M_PATH}/${K3M_CLOUD_INIT}

# get the ipv4 address of the multipass instance
export K3M_INSTANCE_IP=$(multipass info ${K3M_INSTANCE_NAME} | grep IPv4 | awk '{print $2}')

# wait until the kubernetes port is listening
while [ "${EXIT_CODE}" != 0 ]
  do
    sleep 1
    nc -vz -w1 ${K3M_INSTANCE_IP} 6443 &> /dev/null && EXIT_CODE=${?} || EXIT_CODE=${?}
  done

# get the kubeconfig from the multipass instance, replace the localhost ip with the multipass ipv4 address and save to k3m path locally
multipass exec ${K3M_INSTANCE_NAME} -- sed "s/127.0.0.1/${K3M_INSTANCE_IP}/g" /etc/rancher/k3s/k3s.yaml > ${K3M_PATH}/kubeconfig

# print post install info
cat << "EOF"

   __    ____
  / /__ |_  /__ _
 /  '_/_/_ </  ' \
/_/\_\/____/_/_/_/

EOF

echo "To access kubernetes:"
echo "---------------------"
echo "export KUBECONFIG=${K3M_PATH}/kubeconfig"
echo "kubectl get nodes -o wide"
echo ""
echo "To SSH to your multipass instance:"
echo "----------------------------------"
echo "ssh -i ${K3M_SSH_PRIVATE_KEY} multipass@${K3M_INSTANCE_IP}"
echo ""
