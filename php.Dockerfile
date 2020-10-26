# multi-stage build for dockerized nginx with php7

# set up nginx build container
FROM alpine:latest AS nginx
RUN apk add gcc g++ git curl make linux-headers tar gzip

# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

# configure and build nginx
WORKDIR /src/nginx/nginx-"$NGINX_VER"
RUN ./configure --prefix=/usr/share/nginx \
        --sbin-path=/usr/sbin/nginx \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/run/nginx.pid \
        --lock-path=/run/lock/subsys/nginx \
        --http-client-body-temp-path=/tmp/nginx/client \
        --http-proxy-temp-path=/tmp/nginx/proxy \
        --user=www-data \
        --group=www-data \
        --with-threads \
        --with-file-aio \
        --with-pcre="/src/pcre/pcre-$PCRE_VER" \
        --with-pcre-jit \
        --with-http_addition_module \
        --add-module=/src/ngx-fancyindex \
        --without-http_uwsgi_module \
        --without-http_scgi_module \
        --without-http_gzip_module \
        --without-select_module \
        --without-poll_module \
        --without-mail_pop3_module \
        --without-mail_imap_module \
        --without-mail_smtp_module \
        --with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"
ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

# set up the final container
FROM alpine:latest

# copy in default nginx configs
COPY conf/php/nginx/ /etc/nginx/

# setup nginx folders and files
RUN adduser www-data -D -H \
        && mkdir -p /usr/share/nginx/fastcgi_temp && chown -R www-data:www-data /usr/share/nginx/fastcgi_temp \
        && mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/ \
        && mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx \
        && mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html \
        && touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid

RUN chown -R www-data:www-data /etc/nginx

# add nginx binary
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx

# add php
RUN apk --no-cache add supervisor php7 php7-fpm php7-zip php7-curl php7-json php7-session php7-gd php7-xml php7-mysqli php7-openssl php7-iconv php7-mbstring php7-exif php7-ctype

# add php configs
COPY conf/php/php/fpm-pool.conf /etc/php7/php-fpm.d/www.conf
COPY conf/php/php/php.ini /etc/php7/conf.d/custom.ini
COPY conf/php/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# configure entrypoint
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

