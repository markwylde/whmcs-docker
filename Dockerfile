FROM php:7.4-apache

RUN apt-get update && apt-get upgrade -y

RUN apt-get install -y libicu-dev --no-install-recommends \
    zlib1g-dev \
		libfreetype6-dev \
    libmagickwand-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng-dev \
    libzip-dev \
    jpegoptim \
    optipng \
    gifsicle \
    sendmail \
    git-core \
    build-essential \
    openssl \
    libssl-dev \
    libonig-dev \
    python2.7 \
    zip \
    cron \
    libc-client-dev \
    libkrb5-dev \
	&& docker-php-ext-configure pdo_mysql --with-pdo-mysql=mysqlnd \
	&& docker-php-ext-install -j$(nproc) pdo_mysql mysqli calendar intl \
	&& docker-php-ext-configure gd \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap soap xmlrpc zip \
    && a2enmod rewrite \
	&& apt-get purge -y --auto-remove libicu-dev \
	&& rm -rf /var/lib/apt/lists/*

# Configure production php.ini
RUN curl -sS https://raw.githubusercontent.com/php/php-src/master/php.ini-production \
	| sed -e 's/^;\(date.timezone.*\)/\1 \"Etc\/UTC\"/' \
	-e 's/^\(upload_max_filesize =\).*/\1 25M/' \
	-e 's/^\(post_max_size =\).*/\1 25M/' \
	> /usr/local/etc/php/php.ini

# Install ioncube loader
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/
RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ && \
	php_ext_dir="$(php -i | grep extension_dir | head -n1 | awk '{print $3}')" && \
	mv /tmp/ioncube/ioncube_loader_lin_7.4.so "${php_ext_dir}/" && \
    echo "zend_extension = $php_ext_dir/ioncube_loader_lin_7.4.so" \
        > /usr/local/etc/php/conf.d/00-ioncube.ini && \
	rm /tmp/ioncube_loaders_lin_x86-64.tar.gz && \
	rm -rf /tmp/ioncube

COPY whmcs-cron /etc/cron.d/whmcs-cron
RUN chmod 0644 /etc/cron.d/whmcs-cron
RUN crontab /etc/cron.d/whmcs-cron
RUN touch /var/log/cron.log

RUN echo "#!/bin/sh\ncron\n/usr/local/bin/apache2-foreground" > /usr/bin/run
RUN chmod u+x /usr/bin/run
CMD ["run"]
