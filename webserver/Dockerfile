FROM php:7.3.18-apache 

ENV APACHE_DOCUMENT_ROOT /var/www/html/public

RUN a2enmod rewrite \
    && a2enmod ssl

RUN docker-php-ext-install mysqli pdo pdo_mysql

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync && \
    install-php-extensions gd curl dom json mbstring openssl tokenizer zip 

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php --install-dir /usr/local/bin --filename=composer \
    && php -r "unlink('composer-setup.php');"


COPY ./ssl.crt /etc/apache2/ssl/ssl.crt
COPY ./ssl.key /etc/apache2/ssl/ssl.key
COPY ./default-ssl.conf /etc/apache2/sites-enabled/default-ssl.conf

ARG DEV_SITE

RUN echo "ServerName ${DEV_SITE}" >> /etc/apache2/apache2.conf

RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

USER 1000
