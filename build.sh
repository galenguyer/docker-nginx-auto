#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

# if no registry is provided, tag image as "local" registry
registry="${REGISTRY:-local}"

# retrieve latest nginx version
nginx_mainline="$(curl -s 'http://nginx.org/download/' | grep -oP 'href="nginx-\K[0-9]+\.[0-9]+\.[0-9]+' | sort -t. -rn -k1,1 -k2,2 -k3,3 | head -1)"

# if no version is specified, use the mainline version
nginx_version="${1:-$nginx_mainline}"

# pass core count into container for build process
core_count="$(grep -c ^processor /proc/cpuinfo)"

# if no arguments are passed, display usage info and exit
if [ "$#" -ne 1 ]; then
	echo "No nginx version provided. Falling back to mainline version $nginx_version."
fi

# create docker image
docker build \
        --build-arg NGINX_VER="$nginx_version" \
        --build-arg CORE_COUNT="$core_count" \
        -t "$registry"/nginx-simple:"$nginx_version" \
        -t "$registry"/nginx-simple:latest \
        -f simple.Dockerfile .

docker build \
        --build-arg NGINX_VER="$nginx_version" \
        --build-arg CORE_COUNT="$core_count" \
        -t "$registry"/nginx-autoindex:"$nginx_version" \
        -t "$registry"/nginx-autoindex:latest \
        -f autoindex.Dockerfile .

docker build \
        --build-arg NGINX_VER="$nginx_version" \
        --build-arg CORE_COUNT="$core_count" \
        -t "$registry"/nginx-fancyindex:"$nginx_version" \
        -t "$registry"/nginx-fancyindex:latest \
        -f fancyindex.Dockerfile .

docker build \
        --build-arg NGINX_VER="$nginx_version" \
        --build-arg CORE_COUNT="$core_count" \
        -t "$registry"/nginx-react:"$nginx_version" \
        -t "$registry"/nginx-react:latest \
        -f react.Dockerfile .

docker build \
        --build-arg NGINX_VER="$nginx_version" \
        --build-arg CORE_COUNT="$core_count" \
        -t "$registry"/nginx-php:"$nginx_version" \
        -t "$registry"/nginx-php:latest \
        -f php.Dockerfile .

# if a registry is specified, push to it
if [ "$registry" != "local" ]; then
	docker push "$registry"/nginx-simple:"$nginx_version"
	docker push "$registry"/nginx-simple:latest
	docker push "$registry"/nginx-autoindex:"$nginx_version"
	docker push "$registry"/nginx-autoindex:latest
	docker push "$registry"/nginx-fancyindex:"$nginx_version"
	docker push "$registry"/nginx-fancyindex:latest
	docker push "$registry"/nginx-react:"$nginx_version"
	docker push "$registry"/nginx-react:latest
	docker push "$registry"/nginx-php:"$nginx_version"
	docker push "$registry"/nginx-php:latest
fi
