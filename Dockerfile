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

# ... 前面的部分保持不变 ...

# 安装 PHP 扩展
RUN docker-php-ext-install pdo pdo_mysql zip pcntl
RUN pecl install redis && docker-php-ext-enable redis

# 验证 Redis 扩展
RUN php -m | grep redis && \
    echo "Redis extension is enabled"

# 禁用 open_basedir 限制
RUN echo "open_basedir = none" > /usr/local/etc/php/conf.d/no-basedir.ini && \
    echo "disable_functions = none" >> /usr/local/etc/php/conf.d/no-basedir.ini

# 设置正确的目录权限
RUN chmod -R 755 /var/www/html/ && \
    chown -R www-data:www-data /var/www/html/

# 对需要写的目录设置777权限
RUN chmod -R 777 /var/www/html/storage/ \
    /var/www/html/bootstrap/cache/

# 创建必要的目录
RUN mkdir -p /var/www/html/storage/framework/cache \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/storage/app \
    /var/www/html/bootstrap/cache

EXPOSE 80

# 启动命令：显示调试信息
CMD ["sh", "-c", "\
  echo '=== 检查环境 ===' && \
  echo 'Redis扩展:' && php -m | grep redis && \
  echo '当前权限:' && ls -la /var/www/html/ && \
  echo '存储目录权限:' && ls -la /var/www/html/storage/ && \
  echo '=== 启动应用 ===' && \
  php artisan migrate --force && \
  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n\
"]
