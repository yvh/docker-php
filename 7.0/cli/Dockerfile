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
        libsqlite3-0 \
        libxml2 \
        libzip4 \
        libsodium18 \
        xz-utils \
        libicu57 \
        libbz2-1.0 \
        libxslt1.1 \
        libfreetype6 \
        libjpeg62-turbo \
        libpng16-16 \
        libwebp6; \
    apt-get clean; \
    rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
    mkdir -p $PHP_INI_DIR/conf.d

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both -pie"
ENV PHP_VERSION 7.0.33

COPY docker-php-* /usr/local/bin/

RUN set -eux; \
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
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libwebp-dev

RUN set -eux; \
    apt-get update && apt-get install -y $PHP_BUILD_DEPS --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
    if [ ! -d /usr/include/curl ]; then \
        ln -sT /usr/include/x86_64-linux-gnu/curl /usr/local/include/curl; \
    fi; \
    ln -s /usr/include/freetype2 /usr/include/freetype2/freetype; \
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
        --with-sqlite3 \
        --with-gd \
        --with-jpeg-dir=/usr/lib/x86_64-linux-gnu \
        --with-png-dir=/usr/lib/x86_64-linux-gnu \
        --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
        --with-webp-dir=/usr/lib/x86_64-linux-gnu \
        --enable-exif \
        --enable-phar \
        --enable-posix \
        --enable-simplexml \
        --enable-soap \
        --enable-sockets \
        --enable-tokenizer \
        --enable-xml \
        --with-xsl \
        --enable-zip \
        --with-zlib \
        --with-readline \
        --enable-opcache; \
    make -j"$(nproc)"; \
    make install; \
    { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini; \
    docker-php-ext-enable opcache; \
# https://github.com/docker-library/php/issues/443
    pecl update-channels; \
    pecl install -f libsodium; \
    docker-php-ext-enable sodium; \
    pecl clear-cache; \
    rm -rf /tmp/pear ~/.pearrc; \
    docker-php-source delete; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $PHP_BUILD_DEPS; \
# smoke test
    php --version

ENTRYPOINT ["docker-php-entrypoint"]

CMD ["php", "-a"]
