#!/bin/bash

aws-ssh() {
  if [ ! -f "$HOME/.ssh/getracker-aws" ]; then
    echo "AWS SSH key not found. Please create it at ~/.ssh/getracker-aws"
    return 1
  fi

  if [ -z "$1" ] || [ "$1" == "--help" ]; then
    echo "Usage: aws-ssh <instance-name> [--public]"
    echo
    echo "instance-name\t - Name of the EC2 instance to connect to"
    echo "--public\t - Use the public IP address instead of the private IP"
    return 1
  fi

  IP="$1"
  LOOKUP_TYPE="PrivateIpAddress"

  # If a non-IP was provided, look it up via the EC2 API
  if [ ! "$IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]; then
    [ "$2" == "--public" ] && LOOKUP_TYPE="PublicIpAddress"
    echo -n "Resolving: ${IP} -> "
    IP=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=${IP}" | jq -r ".[][].Instances[0].${LOOKUP_TYPE}")
    echo "${IP}"
  fi

  ssh -i ~/.ssh/getracker-aws "ec2-user@${IP}"
}

alias aws-scp="rsync -Pav -e 'ssh -i ~/.ssh/getracker-aws'"

ngrok-getracker() {
  ngrok-docker getracker-legacy-web-1 80 getracker-legacy_app-net getracker
}

gt-cloc() {
  cloc --not-match-f='bootstrap' app/ packages/jamesausten/ tests/ resources/views/ public/assets/sass/ public/assets/js/getracker/ public/assets/js/graph-data-v3.js public/assets/js/angular
}

