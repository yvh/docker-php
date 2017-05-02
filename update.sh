#!/bin/bash
#set -xe

VERSIONS=("$@")
if [ ${#VERSIONS[@]} -eq 0 ]; then
	VERSIONS=(*/)
fi
VERSIONS=("${VERSIONS[@]%/}")

SOURCE_FILES=()
for VERSION in "${VERSIONS[@]}"; do
    if [ ! -f "$VERSION/configure" ]
    then
        echo "File $VERSION/configure does not exists. Skip version"
        continue
    fi

    source $VERSION/configure

    for TARGET in \
		apache \
        fpm \
	; do
        [ -d "$VERSION/$TARGET" ] || continue

        cp -v docker-php-ext-* "$VERSION/$TARGET/"
        cp -v docker-php-source "$VERSION/$TARGET/"
        SOURCE_FILES+=("$VERSION/$TARGET/docker-php-source")
    done

    sed -i '' '
        s|%%TAR_COMPRESSION_FLAG%%|'$TAR_COMPRESSION_FLAG'|;
        s|%%ARCHIVE_EXTENSION%%|'$ARCHIVE_EXTENSION'|;
    ' "${SOURCE_FILES[@]}"
done
