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
  echo ""
  exit 1
fi

# global environment variables
K3M_PATH=~/.k3m
K3M_INSTANCE_USER="ubuntu"
K3M_INSTANCE_IMAGE="bionic"
K3M_INSTANCE_NAME="k3m"
K3M_CLOUD_INIT="cloud-init-k3m.yml"
K3M_SSH_PRIVATE_KEY=~/.ssh/id_rsa
K3M_SSH_PUBLIC_KEY=${K3M_SSH_PRIVATE_KEY}.pub
K3M_ENVIRONMENT_FILE=${K3M_PATH}/env.sh

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

cat << "EOF"

    __    ____
   / /__ |_  /__ _
  /  '_/_/_ </  ' \
 /_/\_\/____/_/_/_/

      -- multipass + k3s = <3

EOF

# deploy multipass instance with generated cloud-config
echo "Deploying Multipass Instance"
multipass launch ${K3M_INSTANCE_IMAGE} --name ${K3M_INSTANCE_NAME} --cloud-init ${K3M_PATH}/${K3M_CLOUD_INIT}

# get the ipv4 address of the multipass instance
echo "Getting the IPv4 Address of ${K3M_INSTANCE_NAME}"
export K3M_INSTANCE_IP=$(multipass info ${K3M_INSTANCE_NAME} | grep IPv4 | awk '{print $2}')

# wait until the kubernetes port is listening
while [ "${EXIT_CODE}" != 0 ]
  do
    sleep 1
    nc -vz -w1 ${K3M_INSTANCE_IP} 6443 &> /dev/null && EXIT_CODE=${?} || EXIT_CODE=${?}
  done

# get the kubeconfig from the multipass instance, replace the localhost ip with the multipass ipv4 address and save to k3m path locally
echo "Writing the kubeconfig to ${K3M_PATH}/kubeconfig"
multipass transfer ${K3M_INSTANCE_NAME}:/etc/rancher/k3s/k3s.yaml ${K3M_PATH}/kubeconfig
sed -i '' "s/127.0.0.1/${K3M_INSTANCE_IP}/g" ${K3M_PATH}/kubeconfig

# save env vars to file
echo "Writing the environment file to ${K3M_ENVIRONMENT_FILE}"
echo "export K3M_PATH=${K3M_PATH}" > ${K3M_ENVIRONMENT_FILE}
echo "export K3M_INSTANCE_USER=${K3M_INSTANCE_USER}" >> ${K3M_ENVIRONMENT_FILE}
echo "export K3M_INSTANCE_NAME=${K3M_INSTANCE_NAME}" >> ${K3M_ENVIRONMENT_FILE}
echo "export K3M_CLOUD_INIT=${K3M_PATH}/${K3M_CLOUD_INIT}" >> ${K3M_ENVIRONMENT_FILE}
echo "export K3M_SSH_PRIVATE_KEY=${K3M_SSH_PRIVATE_KEY}" >> ${K3M_ENVIRONMENT_FILE}
echo alias k3m=\"multipass exec ${K3M_INSTANCE_NAME} -- $\{1}\" >> ${K3M_ENVIRONMENT_FILE}
echo alias k3m-delete=\"multipass delete --purge ${K3M_INSTANCE_NAME}\" >> ${K3M_ENVIRONMENT_FILE}

# write banner info to file
echo "Writing the banner info to ${K3M_PATH}/banner"
echo "" > ${K3M_PATH}/banner
echo "Welcome to:" >> ${K3M_PATH}/banner
echo "" >> ${K3M_PATH}/banner
echo "    __    ____      " >> ${K3M_PATH}/banner
echo "   / /__ |_  /__ _  " >> ${K3M_PATH}/banner
echo "  /  '_/_/_ </  ' \ " >> ${K3M_PATH}/banner
echo " /_/\_\/____/_/_/_/ " >> ${K3M_PATH}/banner
echo "" >> ${K3M_PATH}/banner

echo "
To access Kubernetes:
---------------------
export KUBECONFIG=${K3M_PATH}/kubeconfig
kubectl get nodes -o wide

To SSH to your Multipass Instance:
---------------------------------
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i ${K3M_SSH_PRIVATE_KEY} ubuntu@${K3M_INSTANCE_IP}

If you don't have kubectl installed:
-----------------------------------
source ${K3M_ENVIRONMENT_FILE}
k3m kubectl get nodes -o wide

To destroy the environment:
---------------------------
k3m-delete
" >> ${K3M_PATH}/banner

echo "Deployment completed"
echo ""
sleep 1

cat ${K3M_PATH}/banner
