#!/bin/bash
set -x

if [ ! -f /var/www/_tools/pma/config.secret.inc.php ] ; then
    cat > /var/www/_tools/pma/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`';
EOT
fi

# We remove existing configuration in opcache.ini
grep -v "memory_consumption" /etc/php/7.0/mods-available/opcache.ini > temp && mv temp /etc/php/7.0/mods-available/opcache.ini
grep -v "max_accelerated_files" /etc/php/7.0/mods-available/opcache.ini > temp && mv temp /etc/php/7.0/mods-available/opcache.ini

# We configure opcache.ini with ENV values
cp  /etc/php/7.0/mods-available/opcache.ini /tmp/opcache.ini
echo "opcache.memory_consumption=${OPCACHE_MAX_MEMORY}" >> /tmp/opcache.ini
echo "opcache.max_accelerated_files=${OPCACHE_MAX_FILES}" >> /tmp/opcache.ini
mv /tmp/opcache.ini /etc/php/7.0/mods-available/opcache.ini

if [[ ! -z $TOOLS_HTPASSWD ]]; then
	rm /var/www/_tools/.htpasswd

	for USER in $(echo "$TOOLS_HTPASSWD" | tr ' ' '\n'); do
		IFS=':' read -a address <<< "$USER"
		if [ -f /var/www/_tools/.htpasswd ]; then
			htpasswd -b /var/www/_tools/.htpasswd ${address[0]} ${address[1]}
		else
			htpasswd -cb /var/www/_tools/.htpasswd ${address[0]} ${address[1]}
   		fi
    done
fi

service php7.0-fpm stop && service apache2 stop && service php7.0-fpm start && service apache2 start

exec /bin/bash -i