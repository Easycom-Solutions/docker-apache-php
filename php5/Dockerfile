FROM easycom/base
MAINTAINER Frédéric T <xmedias@easycom.digital>

ENV TOOLS_HTPASSWD easycom:P@ssw0rd
ENV OPCACHE_MAX_MEMORY "128"
ENV OPCACHE_MAX_FILES "12000"
ENV PHP_REDIS_VERSION 2.2.8

RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends ca-certificates wget

## ================================
## Add non-free to source.list
## ================================
RUN echo 'deb http://ftp.fr.debian.org/debian/ jessie main contrib non-free' > /etc/apt/sources.list
RUN echo 'deb-src http://ftp.fr.debian.org/debian/ jessie main contrib non-free' >> /etc/apt/sources.list
RUN echo 'deb http://security.debian.org/ jessie/updates main' >> /etc/apt/sources.list
RUN echo 'deb-src http://security.debian.org/ jessie/updates main' >> /etc/apt/sources.list

## ================================
## Add dotdeb repository to sources to get last version of apache and php for jessie
## ================================
RUN echo 'deb http://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/dotdeb.list
RUN echo 'deb-src http://packages.dotdeb.org jessie all' >> /etc/apt/sources.list.d/dotdeb.list

RUN wget https://www.dotdeb.org/dotdeb.gpg
RUN apt-key add dotdeb.gpg
#RUN apt-get purge -y --auto-remove ca-certificates wget

# =========================================
# Update apt-cache and install Apache2
# =========================================
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y --no-install-recommends install \
	build-essential \
	unzip \
	apache2 \
	libapache2-mod-fastcgi \
	php5 \
	php5-cli \
	php5-fpm \
	php5-curl \
	php5-gd \
	php5-imagick \
	php5-mcrypt \
	php5-dev \
	php5-mysql

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# =========================================
# Activate Apache2 mod_rewrite
# =========================================

#-> Make the directory 'default' for the default vhost and tools directory to handle some tools
RUN mkdir -p /var/www/logs /var/www/_tools /var/www/htdocs

RUN DEBIAN_FRONTEND=noninteractive a2enmod actions rewrite deflate headers 

# Configure apache to be in production mode for better security
ADD ./common/security.conf /etc/apache2/conf-available/security.conf
RUN a2enconf security

# Configure servername to avoid alert in console
RUN echo "ServerName $(cat /etc/hostname)" > /etc/apache2/conf-available/servername.conf
RUN a2enconf servername

# Copy configuration file to secure /tools path by an htaccess // see entrypoint to configure login/pass
ADD ./common/common_tools.conf /etc/apache2/conf-available/common_tools.conf
RUN a2enconf common_tools

# Remove default configuration for virtuals hosts
RUN mkdir _bak 
RUN mv /etc/apache2/sites-available/* _bak/
RUN mv _bak /etc/apache2/sites-available/
RUN rm -Rf /etc/apache2/sites-enabled/*

# Add our configuration for default virtual host
ADD ./common/vhost-default.conf /etc/apache2/sites-available/default.conf
RUN chmod 655 /etc/apache2/sites-available/default.conf
RUN a2ensite default

# Copy "php5-fpm.conf" in Apache2 conf-available > Enable php5 for all sites
ADD ./php5-fpm.conf /etc/apache2/conf-available/php5-fpm.conf
ADD ./php5-fpm.pool /etc/php5/fpm/pool.d/www.conf
RUN chmod 655 /etc/apache2/conf-available/php5-fpm.conf
RUN a2enconf php5-fpm

# Install php-redis extension
RUN cd /tmp \
	&& wget https://github.com/phpredis/phpredis/archive/${PHP_REDIS_VERSION}.zip -O phpredis.zip \
	&& unzip -o /tmp/phpredis.zip && mv /tmp/phpredis-* /tmp/phpredis && cd /tmp/phpredis && phpize && ./configure && make && make install \
	&& echo 'extension=redis.so' > /etc/php5/mods-available/redis.ini \
	&& php5enmod redis \
	&& rm -Rf /tmp/*

# Install opcache monitoring interface
RUN cd /tmp \
	&& wget https://github.com/PeeHaa/OpCacheGUI/archive/master.zip -O OpCacheGUI.zip \
	&& unzip OpCacheGUI.zip && mv OpCacheGUI-* OpCacheGUI \
	&& echo -e "<?php\nnamespace OpCacheGUI;\nuse OpCacheGUI\I18n\FileTranslator;\nuse OpCacheGUI\Network\Router;\nerror_reporting(E_ALL);\nini_set('display_errors', 1);\nini_set('log_errors', 0);\nini_set('date.timezone', 'Europe/Paris');\n\$translator = new FileTranslator(__DIR__ . '/texts', 'fr');\n\$uriScheme = Router::QUERY_STRING;\n\$login = [ 'username' => '', 'password' => '', 'whitelist' => [ '*' ] ];" > OpCacheGUI/init.example.php \
	&& sed -i "s/-e <?php/<?php/" OpCacheGUI/init.example.php \
	&& mv OpCacheGUI /var/www/_tools/opcache

RUN echo "<?php phpinfo();" > /var/www/_tools/info.php

RUN cd /tmp \
	&& wget https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-all-languages.tar.gz \
	&& tar xfz phpMyAdmin* \
	&& rm phpMyAdmin*.tar.gz \
	&& mv phpMyAdmin* /var/www/_tools/pma
ADD ./common/config.inc.php /var/www/_tools/pma/

# =========================================
# Reload Apache2
# =========================================
RUN mv /var/www/html/index.html /var/www/htdocs/ && rm -Rf /var/www/html \
 && service php5-fpm stop && service apache2 stop && service php5-fpm start && service apache2 start

ADD entry-point.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entry-point.sh

## ================================
## LAUNCH PART
## ================================
# Expose sockets
EXPOSE 80 443

# Launch run script
CMD ["entry-point.sh"]
