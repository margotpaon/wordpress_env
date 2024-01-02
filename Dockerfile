#Project based on https://github.com/TrafeX/docker-wordpress

# Use Alpine Linux 3.19.0 as the base image
FROM alpine:3.19.0


ENV DB_HOST="db" \
    DB_NAME="wordpress" \
    DB_USER="wp"\
    DB_PASS="secret" \
    FS_METHOD="direct"


# Install packages
RUN apk --no-cache add \
  php82 \
  php82-fpm \
  php82-mysqli \
  php82-json \
  php82-openssl \
  php82-curl \
  php82-zlib \
  php82-xml \
  php82-phar \
  php82-intl \
  php82-dom \
  php82-xmlreader \
  php82-xmlwriter \
  php82-exif \
  php82-fileinfo \
  php82-sodium \
  php82-gd \
  php82-simplexml \
  php82-ctype \
  php82-mbstring \
  php82-zip \
  php82-opcache \
  php82-iconv \
  php82-pecl-imagick \
  php82-session \
  php82-tokenizer \
  nginx \
  supervisor \
  curl \
  bash \
  less && apk add -u musl && \
    rm -rf /var/cache/apk/*


# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/php-fpm.conf /etc/php82/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php82/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# wp-content volume
VOLUME /var/www/wp-content
WORKDIR /var/www/wp-content
RUN chown -R nobody.nobody /var/www

# WordPress
ENV WORDPRESS_VERSION 6.4.2
ENV WORDPRESS_SHA1 d1aedbfea77b243b09e0ab05b100b782497406dd

RUN mkdir -p /usr/src

# Upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
RUN curl -o wordpress.tar.gz -SL https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz \
  && echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c - \
  && tar -xzf wordpress.tar.gz -C /usr/src/ \
  && rm wordpress.tar.gz \
  && chown -R nobody.nobody /usr/src/wordpress

# Create symlink for php
RUN ln -sf /usr/bin/php82 /usr/bin/php

# Add WP CLI
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp

# WP config
COPY wp-config.php /usr/src/wordpress
RUN chown nobody.nobody /usr/src/wordpress/wp-config.php && chmod 640 /usr/src/wordpress/wp-config.php

# Append WP secrets
COPY wp-secrets.php /usr/src/wordpress
RUN chown nobody.nobody /usr/src/wordpress/wp-secrets.php && chmod 640 /usr/src/wordpress/wp-secrets.php

# Entrypoint to copy wp-content
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/wp-login.php

