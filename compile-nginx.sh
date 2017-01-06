if [ -z "$PCRE_PATH" ]; then PCRE_PATH="/usr/local/Cellar/pcre/8.39"; fi
if [ -z "$APP_PATH" ]; then APP_PATH="../skema"; fi

env CFLAGS="-Wno-error" ./configure \
	--prefix=$APP_PATH/conf \
	--with-http_ssl_module \
	--with-pcre \
	--with-ipv6 \
	--sbin-path=../bin/nginx \
	--with-cc-opt="-std=c99 -g -O0 -I/usr/local/include -I$PCRE_PATH/include" \
	--with-ld-opt="-lm -L/usr/local/lib -L$PCRE_PATH/lib" \
	--conf-path=nginx.conf \
	--pid-path=../temp/run/nginx.pid \
	--lock-path=../temp/run/nginx.lock \
	--http-client-body-temp-path=../temp/client_body_temp \
	--http-proxy-temp-path=../temp/proxy_temp \
	--http-fastcgi-temp-path=../temp/fastcgi_temp \
	--http-uwsgi-temp-path=../temp/uwsgi_temp \
	--http-scgi-temp-path=../temp/scgi_temp \
	--http-log-path=../logs/access.log \
	--error-log-path=../logs/error.log \
	--with-debug \
	--add-module=../ngx_devel_kit \
	--add-module=../set-misc-nginx-module \
	--add-module=../form-input-nginx-module \
	--add-module=../ngx_postgres \
	--add-module=../mustache-nginx-module \
	--add-module=../echo-nginx-module \
	--add-module=../nginx-eval-module \
	--add-module=../ngx_coolkit;
make install;
rm -rf $APP_PATH/conf/fastcgi.conf;
rm -rf $APP_PATH/conf/fastcgi.conf.default;
rm -rf $APP_PATH/conf/fastcgi_params;
rm -rf $APP_PATH/conf/fastcgi_params.default;
rm -rf $APP_PATH/conf/koi-utf;
rm -rf $APP_PATH/conf/koi-win;
rm -rf $APP_PATH/conf/win-utf;
rm -rf $APP_PATH/conf/scgi_params;
rm -rf $APP_PATH/conf/scgi_params.default;
rm -rf $APP_PATH/conf/uwsgi_params;
rm -rf $APP_PATH/conf/uwsgi_params.default;
rm -rf $APP_PATH/conf/html;