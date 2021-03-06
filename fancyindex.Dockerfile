# multi-stage build for dockerized nginx

# set up nginx build container
FROM alpine:latest AS nginx
RUN apk add gcc g++ git curl make linux-headers tar gzip

# download pcre library
WORKDIR /src/pcre
ARG PCRE_VER="8.44"
RUN curl -L -O "https://cfhcable.dl.sourceforge.net/project/pcre/pcre/$PCRE_VER/pcre-$PCRE_VER.tar.gz"
RUN tar xzf "/src/pcre/pcre-$PCRE_VER.tar.gz"

# download nginx source
WORKDIR /src/nginx
ARG NGINX_VER
RUN curl -L -O "http://nginx.org/download/nginx-$NGINX_VER.tar.gz"
RUN tar xzf "nginx-$NGINX_VER.tar.gz"

# download fancy-index module
RUN git clone https://github.com/aperezdc/ngx-fancyindex.git /src/ngx-fancyindex

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
	--without-http_fastcgi_module \
	--without-http_uwsgi_module \
	--without-http_scgi_module \
	--without-http_gzip_module \
	--without-select_module \
	--without-poll_module \
	--without-mail_pop3_module \
	--without-mail_imap_module \
	--without-mail_smtp_module \
	--add-module=/src/ngx-fancyindex \ 
	--with-cc-opt="-Wl,--gc-sections -static -static-libgcc -O2 -ffunction-sections -fdata-sections -fPIE -fstack-protector-all -D_FORTIFY_SOURCE=2 -Wformat -Werror=format-security"
ARG CORE_COUNT="1"
RUN make -j"$CORE_COUNT"
RUN make install

# set up the final container
FROM alpine:latest

# setup nginx folders and files
RUN adduser www-data -D -H \
	&& mkdir -p /tmp/nginx/{client,proxy} && chown -R www-data:www-data /tmp/nginx/ \
	&& mkdir -p /var/log/nginx && chown -R www-data:www-data /var/log/nginx \
	&& mkdir -p /var/www/html && chown -R www-data:www-data /var/www/html \
	&& touch /run/nginx.pid && chown www-data:www-data /run/nginx.pid \
	&& mkdir -p /etc/nginx 

# copy in default nginx configs
COPY conf/fancyindex/ /etc/nginx/

RUN chown -R www-data:www-data /etc/nginx

# add nginx binary
COPY --from=nginx /usr/sbin/nginx /usr/sbin/nginx

# set up health check
RUN apk add curl
HEALTHCHECK CMD curl --fail http://localhost/ || exit 1

# configure CMD
CMD ["/usr/sbin/nginx","-g","daemon off;"]
