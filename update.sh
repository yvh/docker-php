#!/bin/bash
#set -xe

versions=("$@")
if [ ${#versions[@]} -eq 0 ]; then
	versions=(*/)
fi
versions=("${versions[@]%/}")

sourceFiles=()
for version in "${versions[@]}"; do
    if [ ! -f "$version/configure" ]
    then
        echo "File $version/configure does not exists. Skip version"
        continue
    fi
    
    source $version/configure
    
    for target in \
		apache \
        fpm \
	; do
        [ -d "$version/$target" ] || continue
        
        if [ ! -f "$version/configure" ]
        then
            echo "File $version/configure does not exists. Skip version"
            continue
        fi
        
        cp -v docker-php-ext-* "$version/$target/"                
        cp -v docker-php-source "$version/$target/"
        sourceFiles+=("$version/$target/docker-php-source")
    done
    
    sed -ri '
        s|%%TAR_COMPRESSION_FLAG%%|'$TAR_COMPRESSION_FLAG'|;
        s|%%ARCHIVE_EXTENSION%%|'$ARCHIVE_EXTENSION'|;
    ' "${sourceFiles[@]}"
done
