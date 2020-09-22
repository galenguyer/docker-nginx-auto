#!/usr/bin/env bash
# build, tag, and push docker images

# exit if a command fails
set -o errexit

# exit if required variables aren't set
set -o nounset

#set environment variables
mainline_version="1.19.2"
stable_version="1.18.0"
core_count="$(grep -c ^processor /proc/cpuinfo)"

# create docker mainline image
docker build \
	--build-arg NGINX_VER="$mainline_version" \
	--build-arg CORE_COUNT="$core_count" \
	-t nginx:latest \
        -t docker.galenguyer.com/nginx/nginx:latest \
        -t docker.galenguyer.com/nginx/nginx:"$mainline_version" \
	-t nginx-mainline:latest \
        -t docker.galenguyer.com/nginx/nginx-mainline:latest \
        -t docker.galenguyer.com/nginx/nginx-mainline:"$mainline_version" \
        -f Dockerfile .

# create docker stable image
docker build \
	--build-arg NGINX_VER="$stable_version" \
	--build-arg CORE_COUNT="$core_count" \
	-t nginx-stable:latest \
        -t docker.galenguyer.com/nginx/nginx-stable:latest \
        -t docker.galenguyer.com/nginx/nginx-stable:"$stable_version" \
        -f Dockerfile .

docker push docker.galenguyer.com/nginx/nginx:latest
docker push docker.galenguyer.com/nginx/nginx:"$mainline_version"
docker push docker.galenguyer.com/nginx/nginx-mainline:latest
docker push docker.galenguyer.com/nginx/nginx-mainline:"$mainline_version"
docker push docker.galenguyer.com/nginx/nginx-stable:latest
docker push docker.galenguyer.com/nginx/nginx-stable:"$stable_version"

