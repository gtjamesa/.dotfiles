#!/bin/bash

aws-ssh() {
  ssh -i /d/Google\ Drive/Infrastructure/AWS/getracker-aws "ec2-user@$1"
}

#aws-scp() {
#	KEY="/d/Google Drive/Infrastructure/AWS/getracker-aws"
#	echo $KEY
#	echo $1
#	rsync -Pav -e 'ssh -i "$KEY"' ./public/assets/images/icons/ ec2-user@172.31.15.36:/var/www/ge-tracker.com/public/assets/images/icons/
#}

ngrok-getracker() {
  ngrok-docker getracker_appserver_1 80 getracker_default getracker
}

gt-cloc() {
  cloc --not-match-f='bootstrap' app/ packages/jamesausten/ tests/ resources/views/ public/assets/sass/ public/assets/js/getracker/ public/assets/js/graph-data-v3.js public/assets/js/angular
}

discord-export() {
  echo "Exporting channel as HTML"
  docker run --rm -v "$(pwd):/app/out" tyrrrz/discordchatexporter export -t "$DISCORD_BOT_TOKEN" -b -c "$1" -f HtmlDark
  echo "Exporting channel as JSON"
  docker run --rm -v "$(pwd):/app/out" tyrrrz/discordchatexporter export -t "$DISCORD_BOT_TOKEN" -b -c "$1" -f Json
}

#alias dc='docker-compose'
#alias dce='docker-compose exec'

# Lando aliases
alias yaw='lando yarn run watch'
alias yab='lando yarn run build'
alias yat='lando yarn run test'
alias lando-diff-php='lando start && lando rebuild -y -s appserver && rm -rf vendor/ && lando composer install && lando composer du -o && lando artisan view:clear'

# Laravel
alias vapor='php vendor/bin/vapor'

# GE Tracker
alias getracker-flush='lando composer du -o; lando artisan dev:flush-ide-helper; composer fixc'
alias gtinit='cd /d/wamp/www/getracker.local/ && tmux'
#alias ssh-aws='ssh -i /d/Google\ Drive/Infrastructure/AWS/getracker-aws ec2-user@'
#alias aws-scp='scp -i /d/Google\ Drive/Infrastructure/AWS/getracker-aws'
alias aws-scp="rsync -Pav -e 'ssh -i ~/.ssh/getracker-aws'"

alias sitespeed='docker run --rm -v "/d/Google Drive/Infrastructure:/sitespeed.io" sitespeedio/sitespeed.io:12.0.1 -b chrome'
alias coach='docker run --rm -v "/d/Google Drive/Infrastructure:/sitespeed.io" sitespeedio/coach:4.5.0 --details --description -b chrome'

alias ctop='docker run --rm -ti --name=ctop --volume /var/run/docker.sock:/var/run/docker.sock:ro quay.io/vektorlab/ctop:latest'

# Composer local dev
composer-link() {
  jq '.repositories |= [{"type": "path", "url": "'$1'", "options": {"symlink": true}}] + . ' composer.json >composer.tmp.json && mv composer.tmp.json composer.json

  packageName=$(jq -r '.name' "$1/composer.json")

  composer require "$packageName" @dev
}

composer-unlink() {
  git checkout composer.json composer.lock
  composer update
}

# Alias lando to run via Windows cmd.exe
# https://github.com/lando/lando/issues/462#issuecomment-511937745
alias lando='/c/Windows/System32/cmd.exe /c "lando"'

alias adb='/c/Windows/System32/cmd.exe /c "adb"'
