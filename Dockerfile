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

# 创建所有必要的目录
RUN mkdir -p /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/storage/app \
    /var/www/html/bootstrap/cache

# 设置目录所有权
RUN chown -R www-data:www-data /var/www/html/storage \
    /var/www/html/bootstrap/cache

# 设置基础权限
RUN chmod -R 775 /var/www/html/storage \
    /var/www/html/bootstrap/cache

# 为需要完全权限的目录设置777
RUN chmod -R 777 /var/www/html/storage/framework/ \
    /var/www/html/storage/logs/ \
    /var/www/html/storage/app/ \
    /var/www/html/bootstrap/cache/

EXPOSE 80

# 启动命令：修复权限、运行迁移、启动应用
CMD ["sh", "-c", "\
  echo '正在修复文件权限...' && \
  chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache && \
  chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache && \
  chmod -R 777 /var/www/html/storage/framework/ /var/www/html/storage/logs/ /var/www/html/storage/app/ && \
  echo '权限修复完成！' && \
  php artisan migrate --force && \
  echo '数据库迁移完成！' && \
  echo '启动应用中...' && \
  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n\
"]
