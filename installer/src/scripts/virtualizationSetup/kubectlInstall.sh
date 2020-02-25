#!/bin/bash

set -euo pipefail

function install_kubectl {
  sudo apt install -y apt-transport-https
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
  echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
  sudo apt update
  sudo apt install -y kubectl
  if ! kubectl version --client; then
    echo "kubectl installation failed"
    exit 1
  fi
}

kubectl version --client || install_kubectl