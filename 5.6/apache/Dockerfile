FROM debian:jessie
MAINTAINER Yannick Vanhaeren

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkg-config \
    re2c

RUN apt-get update && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ca-certificates \
        curl \
        librecode0 \
        libmysqlclient-dev \
        libsqlite3-0 \
        libxml2 \
        xz-utils \
        libicu52 \
        libbz2-1.0 \
        libxslt1.1 \
        apache2-bin \
        apache2.2-common \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars

RUN set -ex \
	\
# generically convert lines like
#   export APACHE_RUN_USER=www-data
# into
#   : ${APACHE_RUN_USER:=www-data}
#   export APACHE_RUN_USER
# so that they can be overridden at runtime ("-e APACHE_RUN_USER=...")
	&& sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS" \
	\
# setup directories and permissions
	&& . "$APACHE_ENVVARS" \
	&& for dir in \
		"$APACHE_LOCK_DIR" \
		"$APACHE_RUN_DIR" \
		"$APACHE_LOG_DIR" \
		/var/www/html \
	; do \
		rm -rvf "$dir" \
		&& mkdir -p "$dir" \
		&& chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$dir"; \
	done

# Apache + PHP requires preforking Apache for best results
RUN set -ex \
    && a2dismod mpm_event \
    && a2enmod mpm_prefork rewrite
    
RUN set -ex \
    && echo "ServerName localhost" > /etc/apache2/conf-available/fqdn.conf \
    && a2enconf fqdn

# logs should go to stdout / stderr
RUN set -ex \
	&& . "$APACHE_ENVVARS" \
	&& ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log" \
	&& ln -sfT /dev/stdout "$APACHE_LOG_DIR/other_vhosts_access.log"

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

ENV GPG_KEYS 6E4F6AB321FDC07F2C332E3AC2BF0BC433CFC8B3 0BD78B5F97500D450838F95DFE857D9A90D90EC1 8657ABB260F056B1E5190839D9C4D26D0E604491
RUN set -xe \
    && for key in $GPG_KEYS; do \
        gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    done

# compile openssl, otherwise --with-openssl won't work
RUN set -ex \
    && OPENSSL_VERSION="1.0.2j" \
    && cd /tmp \
    && mkdir openssl \
    && curl -SsL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz \
    && curl -SsL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz.asc" -o openssl.tar.gz.asc \
    && gpg --verify openssl.tar.gz.asc \
    && tar -xzf openssl.tar.gz -C openssl --strip-components=1 \
    && cd /tmp/openssl \
    && ./config && make && make install \
    && rm -rf /tmp/*

RUN { \
        echo '<FilesMatch \.php$>'; \
		echo '\tSetHandler application/x-httpd-php'; \
		echo '</FilesMatch>'; \
		echo; \
		echo 'DirectoryIndex disabled'; \
		echo 'DirectoryIndex index.php index.html'; \
		echo; \
		echo '<Directory /var/www/>'; \
		echo '\tOptions -Indexes'; \
		echo '\tAllowOverride All'; \
		echo '</Directory>'; \
	} | tee "$APACHE_CONFDIR/conf-available/docker-php.conf" \
	&& a2enconf docker-php

ENV PHP_VERSION 5.6.27

COPY docker-php-source /usr/local/bin/

RUN set -xe \
    && cd /usr/src \
    && curl -SsL "http://php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" -o php.tar.xz \
    && curl -SsL "http://php.net/get/php-$PHP_VERSION.tar.xz.asc/from/this/mirror" -o php.tar.xz.asc \
    && gpg --verify php.tar.xz.asc

RUN set -xe \
    && PHP_BUILD_DEPS=" \
        libcurl4-openssl-dev \
        libreadline6-dev \
        librecode-dev \
        libsqlite3-dev \
        libssl-dev \
        libxml2-dev \
        libicu-dev \
        libbz2-dev \
        libxslt-dev \
        apache2-dev \
    " \
    && apt-get update && apt-get install -y $PHP_BUILD_DEPS --no-install-recommends \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && . "$APACHE_ENVVARS" \
    && docker-php-source extract \
    && cd /usr/src/php \
    && ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --with-apxs2 \
        --disable-cgi \
        --enable-cli \
        --with-bz2 \
        --enable-ctype \
        --with-curl \
        --enable-dom \
        --enable-fileinfo \
        --enable-filter \
        --with-mhash \
        --with-iconv \
        --enable-intl \
        --enable-json \
        --enable-libxml \
        --enable-mbstring \
        --enable-mbregex \
        --with-mysql \
        --with-mysqli=mysqlnd \
        --enable-mysqlnd \
        --with-openssl \
        --enable-pdo \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --enable-phar \
        --enable-posix \
        --with-recode \
        --enable-simplexml \
        --enable-soap \
        --enable-sockets \
        --with-sqlite3 \
        --enable-tokenizer \
        --enable-xml \
        --with-xsl \
        --enable-zip \
        --with-zlib \
        --with-readline \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && make clean \
    && docker-php-source delete \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $PHP_BUILD_DEPS

COPY docker-php-* /usr/local/bin/

COPY apache2-foreground /usr/local/bin/
WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
