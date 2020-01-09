FROM debian:stretch-slim
LABEL maintainer="Yannick Vanhaeren"

ARG DEBIAN_FRONTEND=noninteractive

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -eux; \
    { \
        echo 'Package: php*'; \
        echo 'Pin: release *'; \
        echo 'Pin-Priority: -1'; \
    } > /etc/apt/preferences.d/no-debian-php

# persistent / runtime deps
ENV PHPIZE_DEPS \
    autoconf \
    dpkg-dev \
    file \
    g++ \
    gcc \
    libc-dev \
    make \
    pkg-config \
    re2c

RUN set -eux; \
    apt-get update && apt-get install -y --no-install-recommends \
        $PHPIZE_DEPS \
        ca-certificates \
        curl \
        librecode0 \
        default-libmysqlclient-dev \
        libsqlite3-0 \
        libxml2 \
        libzip4 \
        libedit2 \
        libsodium18 \
        xz-utils \
        libicu57 \
        libbz2-1.0 \
        libxslt1.1 \
        apache2-bin \
        apache2; \
    apt-get clean; \
    rm -r /var/lib/apt/lists/*

ENV APACHE_CONFDIR /etc/apache2
ENV APACHE_ENVVARS $APACHE_CONFDIR/envvars

RUN set -eux; \
    \
# generically convert lines like
#   export APACHE_RUN_USER=www-data
# into
#   : ${APACHE_RUN_USER:=www-data}
#   export APACHE_RUN_USER
# so that they can be overridden at runtime ("-e APACHE_RUN_USER=...")
    sed -ri 's/^export ([^=]+)=(.*)$/: ${\1:=\2}\nexport \1/' "$APACHE_ENVVARS"; \
    \
# setup directories and permissions
    . "$APACHE_ENVVARS"; \
    for dir in \
        "$APACHE_LOCK_DIR" \
        "$APACHE_RUN_DIR" \
        "$APACHE_LOG_DIR" \
        /var/www/html \
    ; do \
        rm -rvf "$dir"; \
        mkdir -p "$dir"; \
        chown -R "$APACHE_RUN_USER:$APACHE_RUN_GROUP" "$dir"; \
    done

# Apache + PHP requires preforking Apache for best results
RUN set -eux; \
    a2dismod mpm_event; \
    a2enmod mpm_prefork rewrite

RUN set -eux; \
    echo "ServerName localhost" > /etc/apache2/conf-available/fqdn.conf; \
    a2enconf fqdn

RUN set -eux; \
    { \
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
  } | tee "$APACHE_CONFDIR/conf-available/docker-php.conf"; \
  a2enconf docker-php

# logs should go to stdout / stderr
RUN set -eux;\
    . "$APACHE_ENVVARS"; \
    ln -sfT /dev/stderr "$APACHE_LOG_DIR/error.log"; \
    ln -sfT /dev/stdout "$APACHE_LOG_DIR/access.log"

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
    mkdir -p $PHP_INI_DIR/conf.d

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_VERSION 7.1.33

COPY docker-php-source /usr/local/bin/

RUN set -eux; \
    cd /usr/src; \
    curl -SsL "https://secure.php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" -o php.tar.xz

ENV PHP_BUILD_DEPS \
    libcurl4-openssl-dev \
    libreadline6-dev \
    librecode-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    libbz2-dev \
    libxslt-dev \
    libedit-dev \
    apache2-dev \
    libzip-dev \
    zlib1g-dev \
    libsodium-dev

RUN set -eux; \
    apt-get update && apt-get install -y $PHP_BUILD_DEPS --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    . "$APACHE_ENVVARS"; \
    if [ ! -d /usr/include/curl ]; then \
        ln -sT /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl; \
    fi; \
    docker-php-source extract; \
    cd /usr/src/php; \
    ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --with-apxs2 \
        --disable-cgi \
        --enable-cli \
        --with-bz2 \
        --enable-ctype \
        --with-curl \
        --enable-dom \
        --enable-fileinfo \
        --enable-filter \
        --enable-ftp \
        --with-libedit \
        --with-mhash \
        --with-iconv \
        --enable-intl \
        --enable-json \
        --enable-libxml \
        --enable-mbstring \
        --enable-mbregex \
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
        --with-readline; \
    make -j"$(nproc)"; \
    make install; \
    { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini; \
# https://github.com/docker-library/php/issues/443
    pecl update-channels; \
    pecl install -f libsodium; \
    pecl clear-cache; \
    rm -rf /tmp/pear ~/.pearrc; \
    docker-php-source delete; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $PHP_BUILD_DEPS

COPY docker-php-* /usr/local/bin/

RUN set -eux; \
    docker-php-ext-enable sodium

COPY apache2-foreground /usr/local/bin/
WORKDIR /var/www/html

EXPOSE 80
CMD ["apache2-foreground"]
