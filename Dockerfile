# 使用官方 PHP 镜像
FROM php:8.2-fpm-alpine

# 设置工作目录
WORKDIR /var/www/html

# 安装系统依赖
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    git \
    libzip-dev \
    zip \
    unzip \
    nodejs \
    npm \
    $PHPIZE_DEPS

# 安装 PHP 扩展
RUN docker-php-ext-install pdo pdo_mysql zip pcntl
RUN pecl install redis && docker-php-ext-enable redis

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制配置文件
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# 复制 V2Board 代码
COPY . .

# 安装 PHP 依赖
RUN composer install --optimize-autoloader --no-dev

# 安装 NPM 依赖并构建前端
#RUN npm install && npm run build

# 设置权限
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache

# 暴露端口
EXPOSE 80

# 启动 Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
