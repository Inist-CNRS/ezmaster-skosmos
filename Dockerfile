FROM php:7.4.12-apache

# APCU
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

# ldap
RUN apt-get update \
	&& apt-get install -y \
		libldb-dev \
		libldap2-dev --no-install-recommends \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install ldap \
	&& apt-get purge -y \
		libldap2-dev

# gd
RUN apt-get update \
	&& apt-get install -y \
		libfreetype6-dev \
		libpng-dev \
		libjpeg62-turbo-dev \
		libjpeg-dev \
	&& docker-php-ext-configure gd \
	&& docker-php-ext-install -j$(nproc) \
		gd \
	&& apt-get purge -y \
		libfreetype6-dev \
		libpng-dev \
		libjpeg62-turbo-dev \
		libjpeg-dev

# imagick (pecl)
RUN apt-get update \
	&& apt-get install -y \
		libmagickwand-dev --no-install-recommends \
		ghostscript --no-install-recommends \
	&& pecl install \
		imagick \
	&& docker-php-ext-enable \
		imagick \
	&& apt-get purge -y \
		libmagickwand-dev

# xml* & xsl
RUN apt-get update \
	&& apt-get install -y \
		libxml2-dev  libxslt1-dev --no-install-recommends \
	&& CFLAGS="-I/usr/src/php" docker-php-ext-install xml xmlreader xsl \
	&& apt-get purge -y \
		libxml2-dev \
		libxslt1-dev

# zip*
RUN apt-get update \
	&& apt-get install -y \
		libzip-dev \
		zlib1g-dev \
	&& docker-php-ext-install zip \
	&& apt-get purge -y \
		libzip-dev \
		zlib1g-dev

# libsodium
RUN apt-get update \
	&& apt-get install -y \
		libsodium-dev \
	&& pecl install libsodium \
	&& apt-get purge -y \
		libsodium-dev

# mbstring
RUN apt-get update \
	&& apt-get install -y \
		libmcrypt-dev \
		libonig-dev \
	&& docker-php-ext-install mbstring intl \
	&& apt-get purge -y \
		libmcrypt-dev \
		libonig-dev


# Divers
RUN apt-get install -y \
		graphviz \
		esmtp \
	&& docker-php-ext-install -j$(nproc) \
		mysqli \
		exif \
		gettext \
	&& rm -r /var/lib/apt/lists/*

# Plugins Apache
RUN a2enmod rewrite expires

# Install Composer
ARG COMPOSER_VERSION=1.7.2
RUN curl -k -sS https://getcomposer.org/installer | php -- --version=$COMPOSER_VERSION --install-dir=/usr/local/bin --filename=composer

# Install Skosmos
WORKDIR /tmp
ARG SKOSMOS_VERSION=2.8
RUN apt-get update && \
	apt-get install -y git wget unzip locales && \
	wget -q -O Skosmos.zip https://github.com/NatLibFi/Skosmos/archive/v${SKOSMOS_VERSION}.zip && \
    unzip -q Skosmos.zip && \
    mv Skosmos-${SKOSMOS_VERSION} /var/www/html/skosmos && \
    rm -rf Skosmos.zip* Skosmos-${SKOSMOS_VERSION}* && \ 
	locale-gen fr_FR.UTF-8 && locale-gen es_ES.utf8

WORKDIR /var/www/html/skosmos
RUN composer install --no-dev

COPY .htaccess /var/www/html/

RUN cp /var/www/html/skosmos/config.ttl.dist /var/www/html/skosmos/config.ttl
RUN mkdir -p /skosmos/view && \
    mkdir -p /skosmos/resource && \
	mkdir -p /skosmos/plugins

# ezmasterization
# see https://github.com/Inist-CNRS/ezmaster
RUN echo '{ \
  "httpPort": 80, \
  "configPath": "/var/www/html/skosmos/config.ttl", \
  "configType": "text", \
  "dataPath": "/skosmos" \
}' > /etc/ezmaster.json

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["apache2-foreground"]
