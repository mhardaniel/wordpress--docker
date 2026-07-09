FROM wordpress:7.0-php8.3-fpm-alpine

COPY ./custom.ini $PHP_INI_DIR/conf.d/

RUN apk add --no-cache bash less mysql-client \
    && curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x /usr/local/bin/wp
