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

# Check default fpm access
if [[ ! -z $FPM_USERNAME && ! -z $FPM_UID ]]; then
	if [[ -z $FPM_GROUPNAME ]]; then
		FPM_GROUPNAME=$FPM_USERNAME
	fi
	if [[ -z $FPM_GID ]]; then
		FPM_GID=$FPM_UID
	fi

	# If accesses does not match
	# nb lines <= 0
	if [[ `grep $FPM_USERNAME:x:$FPM_UID:$FPM_GID: /etc/passwd | wc -l` -le 0 ]]; then
		# Edit or create group
		if [[ `getent group $FPM_GROUPNAME | wc -l` -le 0 || `getent group $FPM_GID | wc -l` -le 0 ]]; then
			if [[ `getent group $FPM_GROUPNAME | wc -l` -gt 0 ]]; then
				groupmod -g $FPM_GID $FPM_GROUPNAME
			elif [[ `getent group $FPM_GID | wc -l` -gt 0 ]]; then
				groupmod -n $FPM_GROUPNAME `getent group $FPM_GID | cut -d: -f1`
			else
				groupadd -g $FPM_GID $FPM_GROUPNAME
			fi
		fi

		# Edit or create user
		if [[ `getent passwd $FPM_USERNAME | wc -l` -le 0 || `getent passwd $FPM_UID | wc -l` -le 0 ]]; then
			if [[ `getent passwd $FPM_USERNAME | wc -l` -gt 0 ]]; then
				usermod -u $FPM_UID $FPM_USERNAME
			elif [[ `getent passwd $FPM_UID | wc -l` -gt 0 ]]; then
				usermod -l $FPM_USERNAME `getent passwd $FPM_UID | cut -d: -f1`
			else
				useradd -m -u $FPM_UID -g $FPM_GID $FPM_USERNAME
			fi
		fi

		usermod -g $FPM_GID $FPM_USERNAME
		adduser www-data $FPM_GROUPNAME

		# Edit FPM file access
		if [[ -f /etc/php/7.0/fpm/pool.d/www.conf ]]; then
			sed -i -r "s,^user = .+,user = $FPM_USERNAME," /etc/php/7.0/fpm/pool.d/www.conf
			sed -i -r "s,^group = .+,group = $FPM_GROUPNAME," /etc/php/7.0/fpm/pool.d/www.conf
		fi
	fi
fi

service php7.0-fpm stop && service apache2 stop && service php7.0-fpm start && service apache2 start

exec /bin/bash -i