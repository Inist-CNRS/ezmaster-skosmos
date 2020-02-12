FROM php:7.0-apache

RUN apt-get update && apt-get install -y \
		git wget unzip locales \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
		libldap2-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install ldap \
	&& docker-php-ext-install gettext \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

# Install APCu and APC backward compatibility
RUN pecl install apcu \
    && pecl install apcu_bc-1.0.3 \
    && docker-php-ext-enable apcu --ini-name 10-docker-php-ext-apcu.ini \
    && docker-php-ext-enable apc --ini-name 20-docker-php-ext-apc.ini

RUN a2enmod rewrite
RUN a2enmod expires

# Install Composer
ARG COMPOSER_VERSION=1.7.2
RUN curl -k -sS https://getcomposer.org/installer | php -- --version=$COMPOSER_VERSION --install-dir=/usr/local/bin --filename=composer

# Install Skosmos
WORKDIR /tmp
ARG SKOSMOS_VERSION=2.0
RUN wget -q -O Skosmos.zip https://github.com/NatLibFi/Skosmos/archive/v${SKOSMOS_VERSION}.zip && \
    unzip -q Skosmos.zip && \
    mv Skosmos-${SKOSMOS_VERSION} /var/www/html/skosmos && \
    rm -rf Skosmos.zip* Skosmos-${SKOSMOS_VERSION}*

RUN locale-gen fr_FR.UTF-8 && locale-gen es_ES.utf8

WORKDIR /var/www/html/skosmos
RUN composer install --no-dev

COPY .htaccess /var/www/html/

RUN cp /var/www/html/skosmos/config.ttl.dist /var/www/html/skosmos/config.ttl
RUN mkdir -p /skosmos/view && \
    mkdir -p /skosmos/resource && \
	mkdir -p /skosmos/plugins

# ezmasterization
# see https://github.com/Inist-CNRS/ezmaster
# notice: httpPort is useless here but as ezmaster require it (v3.8.1) we just add a wrong port number
RUN echo '{ \
  "httpPort": 80, \
  "configPath": "/var/www/html/skosmos/config.ttl", \
  "configType": "text", \
  "dataPath": "/skosmos" \
}' > /etc/ezmaster.json

COPY docker-entrypoint.sh /usr/local/bin/
ENTRYPOINT [ "docker-entrypoint.sh" ]
CMD ["apache2-foreground"]
