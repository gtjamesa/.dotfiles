#!/bin/bash

# Check to see if the php executable is in the user's path
if [[ -z $(which php) ]]; then
  sudo apt install -y php8.2 php8.2-cli php8.2-common php8.2-opcache php8.2-readline
fi

COMPOSER_PATH="/usr/local/bin/composer"

# Install composer
EXPECTED_CHECKSUM="$(wget -q -O - https://composer.github.io/installer.sig)"
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [[ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]]; then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

php composer-setup.php --quiet
rm composer-setup.php
chmod +x composer.phar
mv composer.phar "$COMPOSER_PATH"

# Install global composer requirements
"$COMPOSER_PATH" global require \
  phpcompatibility/php-compatibility \
  dealerdirect/phpcodesniffer-composer-installer \
  "squizlabs/php_codesniffer=*"
