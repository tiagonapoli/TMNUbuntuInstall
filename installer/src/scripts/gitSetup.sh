#!/bin/bash
set -euo pipefail

display_info() {
  printf "Usage ./start.sh [OPT]\nOptions are:\n"
  printf "  -e: Email from github\n"
  printf "  -u: Username from github\n"
  printf "  -t: Desired editor\n"
  printf "  -h: Show this message\n"
  exit 0
}

EMAIL=""
USERNAME=""
EDITOR=""
while getopts "e:u:t:" OPT; do
  case "$OPT" in
    "e") EMAIL=$OPTARG;;
    "u") USERNAME=$OPTARG;;
    "t") EDITOR=$OPTARG;;
    "h") display_info;;
    "?") display_info;;
  esac 
done

if ["$EMAIL" == ""]; then
  echo "MISSING EMAIL FLAG"
  exit 1
fi

if ["$USERNAME" == ""]; then
  echo "MISSING USERNAME FLAG"
  exit 1
fi

if ["$EDITRO" == ""]; then
  echo "MISSING EDITOR FLAG"
  exit 1
fi

GIT_CONFIG="
[user]
  email = $EMAIL
  name = $USERNAME
[core]
  editor = $EDITOR
[alias]
  tree = log --graph --decorate --pretty=oneline --abbrev-commit
  st = status
  co = checkout
  c = commit -v
  cssh = !sh -c 'git clone git@github.com:\$1 ' -
  rom = rebase origin/master
  undo = reset HEAD~1 --mixed
"

function git_install {
    sudo apt-get -y install git
    echo $GIT_CONFIG > ~/.gitconfig
}

function sshkey_creation {
    rm -rf ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
    ssh-keygen -t rsa -b 4096 -C "$1"
    ssh-add ~/.ssh/id_rsa
}

function send_sshkey_to_github {
    pub=`cat ~/.ssh/id_rsa.pub`
    user=$1
    read -s -p "Enter github password for user $1: " password
    echo ""
    read -p "Enter the 2 factor key: " otp
    echo ""
    auth=$(echo -n $user:$password | base64 -)
    
    ret=$(curl --request POST \
               --url https://api.github.com/user/keys \
               --header "Authorization: Basic $auth" \
               --header "x-github-otp: $otp" \
               --data   "{\"title\":\"`hostname`\",\"key\":\"$pub\"}")
    
    echo $ret
    if echo $ret | grep -q "message"; then
        echo "Error on sending ssh key to github"
        return 1
    else
        return 0
    fi    
}

git_install
sshkey_creation $EMAIL
send_sshkey_to_github $USERNAME || exit 1

read -p "Enter your GITHUB_API_TOKEN (https://help.github.com/en/articles/creating-a-personal-access-token-for-the-command-line): " gitToken

echo "
export GITHUB_API_TOKEN=$gitToken
" >> ~/.bashrc