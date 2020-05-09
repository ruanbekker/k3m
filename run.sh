#!/usr/bin/env bash

# is multipass installed?
which multipass  &> /dev/null && MULTIPASS_EXIT_CODE=${?} || MULTIPASS_EXIT_CODE=${?}
if [ "${MULTIPASS_EXIT_CODE}" == 1 ]
then
  echo "Multipass is not installed:"
  echo "https://multipass.run/docs"
  exit 1
fi

# global environment variables
K3M_PATH=~/.k3m
K3M_INSTANCE_IMAGE="bionic"
K3M_INSTANCE_NAME="k3s"
K3M_CLOUD_INIT="cloud-init-k3s.yml"
K3M_SSH_PUBLIC_KEY=~/.ssh/id_rsa.pub
K3M_SSH_PUBLIC_KEY_CONTENT="$(cat ${K3M_SSH_PUBLIC_KEY})"

# create k3m home directory
mkdir -p ${K3M_PATH}

# check if specified public key exists
if ! [ -f "${K3M_SSH_PUBLIC_KEY}" ] 
  then 
    # create key
    echo "Specified key does not exist, creating ssh key ~/.k3m/ssh_key"
    ssh-keygen -b 2048 -f ${K3M_PATH}/ssh_key -t rsa -C "k3m" -q -N ""
    K3M_SSH_PUBLIC_KEY=${K3M_PATH}/ssh_key.pub
    K3M_SSH_PUBLIC_KEY_CONTENT="$(cat ${K3M_SSH_PUBLIC_KEY})"
fi
