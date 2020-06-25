FROM php:7.3.18-apache 

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV DEBIAN_FRONTEND=noninteractive
ARG DEV_SITE

RUN a2enmod rewrite \
    && a2enmod ssl

RUN useradd --system --create-home --home-dir /home/webuser --shell /bin/bash \
        --gid root --groups sudo --uid 1000 webuser

RUN apt-get update && apt-get install -y unzip \
    && rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && install-php-extensions gd curl dom json mbstring openssl tokenizer zip 

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir /usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"

RUN echo "ServerName ${DEV_SITE}" >> /etc/apache2/apache2.conf

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

USER 1000
