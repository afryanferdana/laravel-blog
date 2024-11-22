FROM serversideup/php:8.3-fpm-nginx AS base

# Switch to root so we can do root things
USER root

# Install the exif extension with root permissions
RUN install-php-extensions exif

# Install JavaScript dependencies
ARG NODE_VERSION=20.18.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "${NODE_VERSION}" /usr/local/node && \
    corepack enable && \
    rm -rf /tmp/node-build-master

# Drop back to our unprivileged user
USER www-data

# Copy the app files...
COPY --chown=www-data:www-data . /var/www/html

# Copy the custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Set correct file permissions for storage and cache directories
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# Re-run install, but now with scripts and optimizing the autoloader (should be faster)...
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Precompiling assets for production
RUN yarn install --immutable && \
    yarn build && \
    rm -rf node_modules
