FROM debian:jessie-slim
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
        bzip2 \
        libicu52 \
        libmysqlclient18 \
        libbz2-1.0 \
        libxslt1.1 \
        libfreetype6 \
        libjpeg62-turbo \
        libpng12-0 \
        libvpx1 \
        libwebp5; \
    apt-get clean; \
    rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN set -eux; \
    mkdir -p $PHP_INI_DIR/conf.d

# compile openssl, otherwise --with-openssl won't work
RUN set -eux; \
    OPENSSL_VERSION="1.0.2r"; \
    cd /tmp; \
    mkdir openssl; \
    curl -SsL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" -o openssl.tar.gz; \
    tar -xzf openssl.tar.gz -C openssl --strip-components=1; \
    cd /tmp/openssl; \
    ./config -fPIC && make && make install; \
    rm -rf /tmp/*

# Apply stack smash protection to functions using local buffers and alloca()
# Make PHP's main executable position-independent (improves ASLR security mechanism, and has no performance impact on x86_64)
# Enable optimization (-O2)
# Enable linker optimization (this sorts the hash buckets to improve cache locality, and is non-default)
# Adds GNU HASH segments to generated executables (this is used if present, and is much faster than sysv hash; in this configuration, sysv hash is also generated)
# https://github.com/docker-library/php/issues/272
ENV PHP_CFLAGS="-fstack-protector-strong -fpic -fpie -O2 -L/usr/lib64 -lstdc++ -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"
ENV PHP_CPPFLAGS="$PHP_CFLAGS"
ENV PHP_LDFLAGS="-Wl,-O1 -Wl,--hash-style=both"
ENV PHP_VERSION 5.3.29

COPY docker-php-* /usr/local/bin/

RUN set -eux; \
    cd /usr/src; \
    curl -SsL "https://secure.php.net/get/php-$PHP_VERSION.tar.bz2/from/this/mirror" -o php.tar.bz2

# php 5.3 needs older autoconf
ENV PHP_BUILD_DEPS \
    autoconf2.13 \
    dpkg-dev \
    libcurl4-openssl-dev \
    libreadline6-dev \
    libsqlite3-dev \
    libxml2-dev \
    libicu-dev \
    libbz2-dev \
    libxslt-dev \
    libmysqlclient-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libvpx-dev \
    libwebp-dev

RUN set -eux; \
    apt-get update && apt-get install -y $PHP_BUILD_DEPS --no-install-recommends; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*; \
    export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS"; \
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
        --with-mysql \
        --with-mysqli=mysqlnd \
        --enable-mysqlnd \
        --with-openssl=/usr/local/ssl \
        --enable-pdo \
        --with-pdo-mysql=mysqlnd \
        --with-pdo-sqlite \
        --with-sqlite3 \
        --with-gd \
        --with-jpeg-dir=/usr/lib/x86_64-linux-gnu \
        --with-png-dir=/usr/lib/x86_64-linux-gnu \
        --with-freetype-dir=/usr/lib/x86_64-linux-gnu \
        --with-vpx-dir=/usr/lib/x86_64-linux-gnu \
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
        --with-readline; \
    make -j"$(nproc)"; \
    make install; \
    { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; }; \
    make clean; \
    cp /usr/src/php/php.ini-production /usr/local/etc/php/php.ini; \
    docker-php-source delete; \
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $PHP_BUILD_DEPS; \
# https://github.com/docker-library/php/issues/443
    pecl update-channels; \
    rm -rf /tmp/pear ~/.pearrc; \
# smoke test
    php --version

ENTRYPOINT ["docker-php-entrypoint"]

CMD ["php", "-a"]
