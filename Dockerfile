FROM ubuntu:18.04

# Add the repository for PHP7.2
# Notice: Have to set LC_ALL to avoid stuff blowing up

RUN apt-get update -y \
	&& apt-get upgrade -y

ENV TZ=Europe/Copenhagen
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
	libapache2-mod-php7.2 \
	php7.2 \
	php7.2-cli \
	php7.2-common \
	php7.2-json \
	php7.2-opcache \
	php7.2-readline \
	php7.2-xml \
	php7.2-dev \
	php7.2-mysql \
	php7.2-soap \
	php7.2-snmp \
	php7.2-pgsql \
	php7.2-sybase \
	php7.2-mbstring \
	php7.2-gd \
	php7.2-xml \
	php7.2-curl \
	git \
	git-core \
	subversion

# Install xdebug (not enabled or configured! See README)
# IMPORTANT NOTE: We're using a specific version and not the master-branch!
# Master is often an unstable alpha which is not even working! 
RUN cd /tmp \
	&& git clone -b xdebug_2_6 git://github.com/xdebug/xdebug.git \
	&& cd xdebug \
	&& phpize \
	&& ./configure --enable-xdebug \
	&& make \
	&& make install \
	&& echo "zend_extension="`find /usr/lib/php -iname 'xdebug.so'` > /etc/php/7.2/mods-available/xdebug.ini \
	&& cat ./xdebug.ini >> /etc/php/7.2/mods-available/xdebug.ini 

# Enable "modrewrite" apache2 mod
RUN a2enmod rewrite

# Provide a vhost for easy testing. Just mount (-v) some local path to /var/www/docker-web
RUN mkdir /var/www/docker-web
ADD ./docker-web.vhost.conf /etc/apache2/sites-enabled/docker-web.vhost.conf

# Change default vhost content
RUN mv /var/www/html/index.html /var/www/html/orig.index.html
RUN echo '<?php phpinfo();' > /var/www/html/index.php

# Ensure apahe2 is started
ENTRYPOINT ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]

