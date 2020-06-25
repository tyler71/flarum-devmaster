FROM composer:2 as extensions

RUN apk add git zip

WORKDIR /build

LABEL "FLARUM_VERSION"="0.1.0-beta.13"
RUN composer create-project flarum/flarum . --stability=dev

RUN composer require \
    fof/drafts:dev-master \
    fof/user-bio:dev-master \
    fof/byobu:dev-master \
    fof/default-group:dev-master \
    fof/discussion-thumbnail:dev-master \
    fof/merge-discussions:dev-master \
    fof/moderator-notes:dev-master \
    askvortsov/flarum-moderator-warnings:dev-master \
    mickmelon/flarum-ext-coloured-usernames:dev-master


FROM php:7.3-apache 

ENV APACHE_DOCUMENT_ROOT /var/www/html/public
ENV DEBIAN_FRONTEND=noninteractive

RUN a2enmod rewrite

RUN useradd --system --create-home --home-dir /home/webuser --shell /bin/bash \
        --gid root --groups sudo --uid 1000 webuser

RUN apt-get update && apt-get install -y unzip \
    && rm -rf /var/lib/apt/lists/*

ADD https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/install-php-extensions /usr/local/bin/

RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && docker-php-ext-install mysqli pdo pdo_mysql \
    && install-php-extensions gd curl dom json mbstring openssl tokenizer zip 


RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

USER 1000

COPY --from=extensions --chown=1000 /build /var/www/html
