FROM cncflora/apache

ADD composer.json /var/www/composer.json
RUN composer self-update && composer install --no-dev

ADD config.yml /var/www/config.yml
ADD resources /var/www/resources
ADD html /var/www/html
ADD src /var/www/src

