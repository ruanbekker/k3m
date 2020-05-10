# k3m

Simplicity of k3s and the speed of multipass, brings you k3m

<img width="992" alt="image" src="https://user-images.githubusercontent.com/567298/81488380-3c0d9a80-9268-11ea-93b7-9b2e5b5b6c13.png">

## About

I really like [Multipass](https://multipass.run) from Canonical and [k3s](https://github.com/rancher/k3s) from Rancher and wanted a one-liner to combine the two together, so that I have a kubernetes development environment running on multipass.

Rancher already makes it so easy to run k3s on its own, and so many amazing community-developed tools such as [k3d](https://github.com/rancher/k3d), [kind](https://github.com/kubernetes-sigs/kind), [k3sup](https://github.com/alexellis/k3sup) (and the list goes on) that makes it super easy to get a environment up and running. But since I use multipass heavily, I wanted to create k3m.

## What does it do?

Get a k3s cluster on multipass with:

```
$ curl -sfL get.k3m.run | bash
$ export KUBECONFIG=~/.k3m/kubeconfig
$ kubectl get nodes -o wide
NAME   STATUS   ROLES    AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k3m    Ready    master   29s   v1.17.4+k3s1   192.168.64.15   <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   containerd://1.3.3-k3s2
```

When the script runs it:

- Generates a `cloud-init.yml`, includes: 
  - the k3s install process
  - adds your default ssh public key, if not present, creates a ssh key under `~/.k3m` and includes it in the cloud-init
- Fetches `/etc/rancher/k3s/k3s.yaml` from the multipass instance, replace the endpoint with the instance ip and save to the local k3m path: `~/.k3m/kubeconfig`
- Saves the environment details under `~/.k3m/env.sh`

## Usage

Deploy k3m:

```
$ curl -sfL get.k3m.run | bash
```

The returned output:

```
    __    ____
   / /__ |_  /__ _
  /  '_/_/_ </  ' \
 /_/\_\/____/_/_/_/

      -- multipass + k3s = <3

Deploying Multipass Instance
Launched: k3m
Getting the IPv4 Address of k3m
Writing the kubeconfig to /Users/ruan/.k3m/kubeconfig
Writing the environment file to /Users/ruan/.k3m/env.sh
Writing the banner info to /Users/ruan/.k3m/banner
Deployment completed


Welcome to:

    __    ____
   / /__ |_  /__ _
  /  '_/_/_ </  ' \
 /_/\_\/____/_/_/_/


To access Kubernetes:
---------------------
export KUBECONFIG=/Users/ruan/.k3m/kubeconfig
kubectl get nodes -o wide

To SSH to your Multipass Instance:
---------------------------------
ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i /Users/ruan/.ssh/id_rsa ubuntu@192.168.64.15

If you don't have kubectl installed:
-----------------------------------
source /Users/ruan/.k3m/env.sh
k3m kubectl get nodes -o wide

To destroy the environment:
---------------------------
k3m delete
```

If you have kubectl installed access k3s with:

```
$ export KUBECONFIG=/Users/ruan/.k3m/kubeconfig
$ kubectl get nodes -o wide
NAME   STATUS   ROLES    AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k3m    Ready    master   29s   v1.17.4+k3s1   192.168.64.15   <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   containerd://1.3.3-k3s2
``

To ssh to your k3m multipass instance:

```
$ ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -i /Users/ruan/.ssh/id_rsa ubuntu@192.168.64.15
ubuntu@k3m:~$
````

If you don't have kubectl installed, source the k3m env file:

```
$ source ~/.k3m/env.sh
```

Then use kubectl as an argument with k3m:

```
$ k3m kubectl get nodes -o wide
NAME   STATUS   ROLES    AGE   VERSION        INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION      CONTAINER-RUNTIME
k3m    Ready    master   84s   v1.17.4+k3s1   192.168.64.15   <none>        Ubuntu 18.04.4 LTS   4.15.0-99-generic   containerd://1.3.3-k3s2
```

To destroy the environment:

```
$ k3m-delete
```

## Taking it further

Now that you have a kubernetes environment running, use [arkade](https://github.com/alexellis/arkade) to easily deploy applications to your kubernetes cluster.
