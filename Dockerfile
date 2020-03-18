FROM php:7.3-alpine

LABEL maintainer="DuyLK <leduyptit@gmail.com>, leduyptit <github.com/leduyptit>"

ARG PHALCON_VERSION=3.4.2
ARG PHALCON_EXT_PATH=php7/64bits

RUN set -xe && \
        cd /tmp/ \
        && curl -LO https://github.com/phalcon/cphalcon/archive/v${PHALCON_VERSION}.tar.gz && \
        tar xzf /tmp/v${PHALCON_VERSION}.tar.gz && \
        docker-php-ext-install -j $(getconf _NPROCESSORS_ONLN) /tmp/cphalcon-${PHALCON_VERSION}/build/${PHALCON_EXT_PATH} && \
        rm -r \
            /tmp/v${PHALCON_VERSION}.tar.gz \
            /tmp/cphalcon-${PHALCON_VERSION}

ARG BUILD_DATE
ARG VCS_REF

ENV \
        APACHE_RUN_USER=www-data \
        APACHE_RUN_GROUP=www-data \
        APACHE_LOG_DIR=/var/log/apache2 \
        APACHE_PID_FILE=/var/run/apache2.pid \
        APACHE_RUN_DIR=/var/run/apache2 \
        APACHE_LOCK_DIR=/var/lock/apache2 \
        COMPOSER_ALLOW_SUPERUSER=1\
        DEPS="apache2 \
        php7.3 \
        php7.3-phar \
        php7.3-bcmath \
        php7.3-calendar \
        php7.3-mbstring \
        php7.3-exif \
        php7.3-ftp \
        php7.3-openssl \
        php7.3-zip \
        php7.3-sysvsem \
        php7.3-sysvshm \
        php7.3-sysvmsg \
        php7.3-shmop \
        php7.3-sockets \
        php7.3-zlib \
        php7.3-bz2 \
        php7.3-curl \
        php7.3-simplexml \
        php7.3-xml \
        php7.3-opcache \
        php7.3-dom \
        php7.3-xmlreader \
        php7.3-xmlwriter \
        php7.3-tokenizer \
        php7.3-ctype \
        php7.3-session \
        php7.3-fileinfo \
        php7.3-iconv \
        php7.3-json \
        php7.3-posix \
        php7.3-apache2 \
        php7.3-pdo \
        php7.3-pdo_mysql \
        php7.3-redis \
        curl \
        ca-certificates \
        runit"

RUN mkdir -p $APACHE_RUN_DIR $APACHE_LOCK_DIR $APACHE_LOG_DIR

# PHP.earth Alpine repository for better developer experience
ADD https://repos.php.earth/alpine/phpearth.rsa.pub /etc/apk/keys/phpearth.rsa.pub

RUN set -x \
    && echo "https://repos.php.earth/alpine/v3.8" >> /etc/apk/repositories \
    && apk --no-cache add $DEPS \
    # && mkdir /run/apache2 \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

COPY tags/apache /
RUN chmod -R 0777 /sbin/runit-wrapper && chmod -R 0777 /sbin/runsvdir-start && chmod -R 0777 /etc/service/apache/run

# COPY 000-default-website.conf /etc/apache2/conf.d/000-default.conf

RUN sed -i '/LoadModule rewrite_module/s/^#//g' /etc/apache2/httpd.conf && \
    sed -i 's#AllowOverride [Nn]one#AllowOverride All#' /etc/apache2/httpd.conf

RUN httpd -v && which httpd
EXPOSE 80

CMD ["/bin/sh", "-c", "/sbin/runit-wrapper"]