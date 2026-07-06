#!/bin/bash

# Work: PHP/Laravel/getracker development. Enable with: dotmod enable work

discord-export() {
  echo "Exporting channel as HTML"
  docker run --rm -v "$(pwd):/app/out" tyrrrz/discordchatexporter export -t "$DISCORD_BOT_TOKEN" -b -c "$1" -f HtmlDark
  echo "Exporting channel as JSON"
  docker run --rm -v "$(pwd):/app/out" tyrrrz/discordchatexporter export -t "$DISCORD_BOT_TOKEN" -b -c "$1" -f Json
}

# Docker aliases
alias yaw='docker-compose exec node yarn dev'
alias yab='docker-compose exec node yarn build'
alias yat='docker-compose exec node yarn test'
alias tinker='docker-compose exec app php artisan tinker'
alias app-bash="docker-compose exec -u ${1:-1000} app bash"
alias vapor='php ./vendor/bin/vapor'

alias sitespeed='docker run --rm -v "/mnt/d/Google Drive/Infrastructure:/sitespeed.io" sitespeedio/sitespeed.io:12.0.1 -b chrome'
alias coach='docker run --rm -v "/mnt/d/Google Drive/Infrastructure:/sitespeed.io" sitespeedio/coach:4.5.0 --details --description -b chrome'

# Laravel
alias llog='clear; touch storage/logs/laravel-$(date +%F).log; tail -f -n 0 storage/logs/laravel-$(date +%F).log'

rector() {
  docker run --rm -v "$(pwd):/project" rector/rector:latest process "/project/$1" --config="/project/rector.yaml" --autoload-file /project/vendor/autoload.php
}

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

# Access Redis running inside docker-compose
# Usage: redis-cli [filter]
redis-cli() {
  if [ "$1" == "--help" ]; then
    echo "Usage: redis-cli [filter] [--short]"
    return 0
  fi

  [ -z "$1" ] && docker-compose exec redis redis-cli

  if [ -n "$1" ]; then
    if [ "$2" == "--short" ]; then
      docker-compose exec redis redis-cli monitor | tee | grep "$1" | awk '{print $4" "$5}'
    else
      docker-compose exec redis redis-cli monitor | tee | grep "$1"
    fi
  fi
}

# PHP Compatibility checker
# composer global require phpcompatibility/php-compatibility dealerdirect/phpcodesniffer-composer-installer "squizlabs/php_codesniffer=*"
phpcc() {
  # If no directory is specified, we should automatically build directories
  if [[ -z $1 ]]; then
    AVAIL_DIRS=('app' 'src' 'tests' 'packages')
    CHECK_DIRS=''
    CHECK_DIR_CMD=''

    # Build command string if the directory exists
    for x in "${AVAIL_DIRS[@]}"
    do
      if [[ -d "$x" ]]; then
        CHECK_DIRS="$x $CHECK_DIRS"
        CHECK_DIR_CMD="-p $x $CHECK_DIR_CMD"
      fi
    done
  else
    CHECK_DIRS="$1"
    CHECK_DIR_CMD="-p $1"
  fi

  if [[ -z "$CHECK_DIR_CMD" ]]; then
    echo "No directories found in CWD from list: $AVAIL_DIRS"
    return 1
  fi

  TEST_VERSION='8.0-'
  if [[ -n $2 ]]; then
    TEST_VERSION="$2"
  fi

  RUN_CMD="phpcs $CHECK_DIR_CMD --standard=PHPCompatibility --runtime-set testVersion $TEST_VERSION"

  echo "Testing PHP compatibility for $TEST_VERSION in $CHECK_DIRS"
  eval "$RUN_CMD"
}

senv() {
  sudo -v

  BRANCH="$1"
  DUMP_PATH="/mnt/d/Google Drive/Development/2022 Rebuild/Dumps/"
  FILE_PATH=$(ls -tr "$DUMP_PATH" | grep -E "$BRANCH-.+.tar.zst" | tail -1)
  TAR_ARCHIVE=$(basename "$FILE_PATH")

  git checkout "$BRANCH"

  echo
  echo -n "Copying vendor and node_modules archive from $TAR_ARCHIVE... "
  cp "/mnt/d/Google Drive/Development/2022 Rebuild/Dumps/$TAR_ARCHIVE" .
  echo -e "${COLOR_GREEN}Done${COLOR_RESET}"

  echo -n 'Removing old vendor and node_modules... '
  sudo rm -rf vendor/ node_modules/
  echo -e "${COLOR_GREEN}Done${COLOR_RESET}"

  echo -n 'Extracting archive... '
  ztar -x "$TAR_ARCHIVE"
  rm -f "$TAR_ARCHIVE"
  echo -e "${COLOR_GREEN}Done${COLOR_RESET}"

  # Ensure husky permissions are correct
  [ -f .husky/pre-commit ] && chmod +x .husky/pre-commit
  [ -f .husky/_/husky.sh ] && chmod +x .husky/_/husky.sh
}

benv() {
  BRANCH=$(git symbolic-ref --short -q HEAD 2>/dev/null)

  if [[ "$BRANCH" == "" || "$?" -ne 0 ]]; then
    echo 'Not in a git repository'
    return 1
  fi

  DUMP_PATH="/mnt/d/Google Drive/Development/2022 Rebuild/Dumps/"
  TODAY=$(date +%Y%m%d)
  TAR_ARCHIVE="$BRANCH-$TODAY.tar.zst"

  if [[ -f "$DUMP_PATH$TAR_ARCHIVE" ]]; then
    rm -f "$DUMP_PATH$TAR_ARCHIVE"
  fi

  echo -n 'Backing up vendor and node_modules... '
  ztar "$TAR_ARCHIVE" node_modules/ vendor/
  echo -e "${COLOR_GREEN}Done${COLOR_RESET}"

  echo -n 'Moving file... '
  mv "$TAR_ARCHIVE" "$DUMP_PATH"
  echo -e "${COLOR_GREEN}Done${COLOR_RESET}"

  echo -e "${COLOR_GREEN}Created ${TAR_ARCHIVE}${COLOR_RESET}"
}

# Run PHP inside a local docker container using the "getracker/php-base" image
lphp() {
  # grep -oP '"php": "(?:\^(?:\d\.\d)\|)?\^(?:\d\.\d)"' composer.json
  # if [ -f composer.json ] && grep -q '"php":' package.json ; then
  PHP_VERS="8.3"

  # if first argument patches a PHP version, use that
  if [[ "$1" =~ ^[0-9]+\.[0-9]+$ ]]; then
    PHP_VERS="$1"
    shift
  fi

  CMD_ARGS="${@}"

  # Default args to bash if not defined
  [ -z "$CMD_ARGS" ] && CMD_ARGS="bash"

  docker run --rm -it -v "$(pwd):/var/www" "getracker/php-base:${PHP_VERS}-dev_fpm" "${CMD_ARGS}"
}

cl-help() {
  echo -e "${COLOR_GREEN}build${COLOR_RESET}\t\t Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)"
  echo -e "${COLOR_GREEN}chore${COLOR_RESET}\t\t Other changes that don't modify src or test files"
  echo -e "${COLOR_GREEN}ci${COLOR_RESET}\t\t Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs)"
  echo -e "${COLOR_GREEN}docs${COLOR_RESET}\t\t Documentation only changes"
  echo -e "${COLOR_GREEN}feat${COLOR_RESET}\t\t A new feature"
  echo -e "${COLOR_GREEN}fix${COLOR_RESET}\t\t A bug fix"
  echo -e "${COLOR_GREEN}perf${COLOR_RESET}\t\t A code change that improves performance"
  echo -e "${COLOR_GREEN}refactor${COLOR_RESET}\t A code change that neither fixes a bug nor adds a feature"
  echo -e "${COLOR_GREEN}revert${COLOR_RESET}\t\t Reverts a previous commit"
  echo -e "${COLOR_GREEN}style${COLOR_RESET}\t\t Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)"
  echo -e "${COLOR_GREEN}test${COLOR_RESET}\t\t Adding missing tests or correcting existing tests"
  echo -e "${COLOR_GREEN}types${COLOR_RESET}\t\t Changes that affect the typescript type definitions"
  echo -e "${COLOR_GREEN}wip${COLOR_RESET}\t\t Work in progress (should be removed before merging)"
}

create-npm-token() {
  local perm="read-write" perm_label="RW" secret_name="NPM_TOKEN" org="" token_name=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat <<EOF
Usage: create-npm-token [-r] [-n SECRET_NAME] [-o [ORG]] [TOKEN_NAME]

Creates a 90-day npm token scoped to @getracker and stores it as a GitHub
Actions secret. npm token create is interactive (password/2FA) — its prompt and
the freshly-minted token both print here; the token is then captured and set as
the secret for you (no pasting).

  -r, --read-only        Create a read-only token (for installing updates).
                         Default is read-write (for publishing).
  -n, --secret-name NAME GitHub secret name. Default: NPM_TOKEN.
  -o, --org [ORG]        Set the secret at the org level (visibility: all)
                         instead of on the current repo. ORG defaults to
                         getracker.

TOKEN_NAME defaults to "<dirname> <RW|RO> <YYYYMMDD>".
EOF
        return 0
        ;;
      -r|--read-only) perm="read-only"; perm_label="RO"; shift ;;
      -n|--secret-name) secret_name="$2"; shift 2 ;;
      -o|--org)
        if [[ -n "$2" && "$2" != -* ]]; then org="$2"; shift 2; else org="getracker"; shift; fi
        ;;
      *) token_name="$1"; shift ;;
    esac
  done

  token_name="${token_name:-${PWD##*/} ${perm_label} $(date +%Y%m%d)}"

  # npm logins lapse after ~2h; fail early with guidance instead of stalling on a
  # half-expired auth state.
  if ! npm whoami >/dev/null 2>&1; then
    echo -e "${COLOR_RED}npm auth expired/absent — run 'npm login' first ('npm whoami' must pass)${COLOR_RESET}" >&2
    return 1
  fi

  echo -e "Creating ${COLOR_GREEN}${token_name}${COLOR_RESET} (${perm})" >&2

  # npm token create writes BOTH its interactive password/2FA prompt and the token to
  # stdout (reading the password from stdin), so a plain $(...) capture hides the prompt
  # and just blocks. tee /dev/tty mirrors stdout back to the terminal so the prompt shows
  # while we still capture the output to grab the token. The token flashes on screen here
  # — inherent (prompt + token share stdout); the GitHub hand-off stays off argv/history.
  # Do NOT add --json (it suppresses the prompt).
  local create_out token
  create_out=$(npm token create \
    --name "$token_name" \
    --bypass-2fa --expires 90 \
    --orgs-permission "$perm" \
    --orgs getracker \
    --packages-and-scopes-permission "$perm" \
    --scopes @getracker | tee /dev/tty)
  token=$(grep -oE 'npm_[A-Za-z0-9]{36,}' <<<"$create_out" | head -1)
  if [[ -z "$token" ]]; then
    echo -e "${COLOR_RED}could not parse token from npm output (auth cancelled / npm error?); aborting${COLOR_RESET}" >&2
    return 1
  fi

  # Feed the value to gh via stdin (gh reads the secret from stdin when --body is
  # omitted) so it never lands in argv, shell history, or a captured log.
  if [[ -n "$org" ]]; then
    printf '%s' "$token" | gh secret set "$secret_name" --org "$org" --visibility all >&2 || return 1
  else
    printf '%s' "$token" | gh secret set "$secret_name" >&2 || return 1
  fi
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} GitHub secret ${secret_name} set${org:+ (org: ${org})}" >&2
}

# Rotate the read-only @getracker npm install token. npm now makes token *creation*
# interactive (password/2FA) and writes the prompt to the same stream as the token, so
# capturing it from a script fights npm's design (it just blocks). Instead you mint the
# token yourself and this syncs it to the consumers: the GitHub org secret and the
# matching Mend Renovate org secret (so hosted Renovate can install our private
# @getracker packages). The old token lapses at its 90-day expiry.
#
# Requires $MEND_RENOVATE_TOKEN: a GitHub PAT identifying a member of the org in Mend
# (classic: 'repo'; fine-grained: resource owner = getracker, metadata read-only). It
# authenticates to Mend's API only — NOT the npm token.
rotate-npm-token() {
  case " $* " in
    *" -h "*|*" --help "*)
      cat <<EOF
Usage: rotate-npm-token

Syncs a read-only @getracker npm token to its consumers. You mint the token
(npm token create, or npmjs.com/settings/~/tokens); this pushes it to the GitHub
org secret NPM_INSTALL_TOKEN (org: getracker) and the Mend Renovate org secret of
the same name, so hosted Renovate can install our private @getracker packages.

Requires \$MEND_RENOVATE_TOKEN — a GitHub PAT for a getracker org member
(classic: 'repo'; fine-grained: resource owner = getracker, metadata read-only).
EOF
      return 0 ;;
  esac

  local org="getracker" secret_name="NPM_INSTALL_TOKEN"

  if [[ -z "$MEND_RENOVATE_TOKEN" ]]; then
    echo -e "${COLOR_RED}MEND_RENOVATE_TOKEN unset — GitHub PAT for a '${org}' member (repo / metadata)${COLOR_RESET}" >&2
    return 1
  fi

  # Mint it yourself — npm token create is interactive (password/2FA) and prints the
  # token once; then paste it below.
  cat >&2 <<EOF
Create a read-only @getracker token (shown once), e.g.:

  npm token create --read-only --expires 90 \\
    --orgs-permission read-only --orgs ${org} \\
    --packages-and-scopes-permission read-only --scopes @${org} \\
    --name "${org} NPM_READ_TOKEN $(date +%Y%m%d)"

(or via https://www.npmjs.com/settings/~/tokens), then paste it here.
EOF

  # read -rs: silent (no echo), not stored in shell history, never on any argv.
  local token
  printf 'npm token: ' >&2
  read -rs token; echo >&2
  token="${token//[[:space:]]/}"
  if [[ "$token" != npm_* ]]; then
    echo -e "${COLOR_RED}that doesn't look like an npm token (should start with npm_); aborting${COLOR_RESET}" >&2
    unset token; return 1
  fi

  echo -e "Setting GitHub org secret ${COLOR_GREEN}${secret_name}${COLOR_RESET} (org: ${org})" >&2
  printf '%s' "$token" | gh secret set "$secret_name" --org "$org" --visibility all >&2 || { unset token; return 1; }
  echo -e "${COLOR_GREEN}✓${COLOR_RESET} GitHub org secret ${secret_name} set" >&2

  echo -e "Updating Mend org secret ${COLOR_GREEN}${secret_name}${COLOR_RESET} (org: ${org})" >&2
  # Token to jq via env, JSON body to curl via stdin -> stays off both processes' argv
  # (only the long-lived Mend PAT header remains).
  if _NPM_TOK="$token" jq -nc --arg n "$secret_name" \
        '{secretName:$n,secretValue:env._NPM_TOK,envVar:false}' \
      | curl -fsS -X PUT \
          -H "Authorization: ${MEND_RENOVATE_TOKEN}" \
          -H "Content-Type: application/json" \
          -H "mend-appId: 1" \
          --data @- \
          "https://developer-api.mend.io/api/v1/orgs/github/${org}/secrets/${secret_name}" >/dev/null; then
    echo -e "${COLOR_GREEN}✓${COLOR_RESET} Mend org secret ${secret_name} updated" >&2
  else
    echo -e "${COLOR_RED}Mend secret update failed (GitHub secret is already set)${COLOR_RESET}" >&2
    unset token; return 1
  fi
  unset token
}

ri() {
  # If we have a package.json and it contains "np" then use that instead
  if [ -f package.json ] && grep -q '"np":' package.json ; then
    echo -e "[${COLOR_BLUE}"${COLOR_CYAN}\!${COLOR_RESET}"${COLOR_RESET}] ${COLOR_GREEN}Running \"yarn np\"${COLOR_RESET}"
    yarn np
    return 0
  fi

  # Create .release-it.json if it doesn't exist
  if [ ! -f .release-it.json ] && [ -d .git ]; then
  cat <<EOF > .release-it.json
{
  "npm": {
    "ignoreVersion": true,
    "publish": false
  }
}
EOF
  fi

  release-it --only-version
}
