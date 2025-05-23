ARG BASE_IMAGE=scratch

FROM $BASE_IMAGE

LABEL maintainer="Yannick Vanhaeren"

ARG DEBIAN_FRONTEND=noninteractive
ARG PHP_VERSION
ARG OS_PHP_DEPS

# prevent Debian's PHP packages from being installed
# https://github.com/docker-library/php/pull/542
RUN set -e; \
    { \
        echo 'Package: php*'; \
        echo 'Pin: release *'; \
        echo 'Pin-Priority: -1'; \
    } > /etc/apt/preferences.d/no-debian-php

RUN set -e; \
    apt-get update && apt-get install -y --no-install-recommends \
        autoconf \
        dpkg-dev \
        file \
        g++ \
        gcc \
        libc-dev \
        make \
        pkg-config \
        re2c \
        ca-certificates \
        curl \
        libsqlite3-0 \
        libxml2 \
        libzip4 \
        libsodium23 \
        xz-utils \
        libbz2-1.0 \
        libxslt1.1 \
        libargon2-1 \
        libonig5 \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        $OS_PHP_DEPS; \
    apt-get clean; \
    rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -e; \
    mkdir -p $PHP_INI_DIR/conf.d

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -pie"
ENV PHP_VERSION=$PHP_VERSION

COPY docker-php-* /usr/local/bin/

RUN set -e; \
    cd /usr/src; \
    curl -SsL "https://secure.php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" -o php.tar.xz

ENV PHP_BUILD_DEPS \
    libcurl4-openssl-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libssl-dev \
    libxml2-dev \
    libicu-dev \
    libbz2-dev \
    libxslt-dev \
    libzip-dev \
    zlib1g-dev \
    libsodium-dev \
    default-libmysqlclient-dev \
    libargon2-dev \
    libonig-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev

RUN set -e; \
    apt-get update && apt-get install -y $PHP_BUILD_DEPS --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    if [ ! -d /usr/include/curl ]; then \
        ln -sT /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl; \
    fi; \
    ln -s /usr/include/freetype2 /usr/include/freetype2/freetype; \
# temporary "freetype-config" workaround for https://github.com/docker-library/php/issues/865 (https://bugs.php.net/bug.php?id=76324)
    { echo '#!/bin/sh'; echo 'exec pkg-config "$@" freetype2'; } > /usr/local/bin/freetype-config && chmod +x /usr/local/bin/freetype-config; \
    docker-php-source extract; \
    cd /usr/src/php; \
    gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)"; \
    ./configure \
        --build="$gnuArch" \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        --enable-option-checking=fatal \
        --disable-cgi \
        --enable-cli \
        --with-bz2 \
        --enable-ctype \
        --with-curl \
        --enable-dom \
        --enable-fileinfo \
        --enable-filter \
        --enable-ftp \
        --with-mhash \
        --with-iconv \
        --enable-intl \
        --with-libxml \
        --enable-mbstring \
        --enable-mbregex \
        --with-mysqli=mysqlnd \
        --enable-mysqlnd \
        --with-password-argon2 \
        --with-sodium \
        --with-openssl \
        --enable-pdo \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --with-sqlite3 \
        --enable-gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --enable-exif \
        --enable-phar \
        --enable-posix \
        --enable-simplexml \
        --enable-soap \
        --enable-sockets \
        --with-sqlite3 \
        --enable-tokenizer \
        --enable-xml \
        --with-xsl \
        --with-zip \
        --with-zlib \
        --with-pear \
        --with-readline \
        --enable-opcache; \
    make -j"$(nproc)"; \
    find -type f -name '*.a' -delete; \
    make install; \
    { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini; \
    docker-php-ext-enable opcache; \
    docker-php-source delete; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $PHP_BUILD_DEPS; \
# https://github.com/docker-library/php/issues/443
    pecl update-channels; \
    rm -rf /tmp/pear ~/.pearrc; \
# smoke test
    php --version

ENTRYPOINT ["docker-php-entrypoint"]

CMD ["php", "-a"]
