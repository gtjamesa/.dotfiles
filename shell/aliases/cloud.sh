#!/bin/bash

# AWS
ec2-status() {
  aws ec2 describe-instances --instance-ids "$1" | jq ".Reservations[0].Instances[0].State.Name"
}

ngrok-docker() {
  if [ "$1" == "--help" ]; then
    echo "Usage: $0 <container> <port> <network> <subdomain>"
    echo
    echo "container\t - Container name"
    echo "port\t\t - Container port to expose"
    echo "network\t\t - Network to use (default: bridge)"
    echo "subdomain\t - Subdomain to use"
    echo -e "\nExample: $0 mycontainer 80"
    return 0
  fi

  DOCKER_CONTAINER="$1"
  DOCKER_PORT="$2"
  DOCKER_NETWORK=${3:-bridge}
  SUBDOMAIN="${4}.ngrok.io"

  CMD="docker run --rm -it --name ngrok -p 4040:4040 --link ${DOCKER_CONTAINER} --network ${DOCKER_NETWORK} -v ${HOME}/.ngrok2/:/home/ngrok/.config/ngrok/ wernight/ngrok ngrok http --domain=${SUBDOMAIN} ${DOCKER_CONTAINER}:${DOCKER_PORT}"
  echo "$CMD"
  tmux new-window "$CMD"
  tmux rename-window ngrok
}
