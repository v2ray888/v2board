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

# 验证 Redis 扩展
RUN echo "检查 Redis 扩展:" && php -m | grep redis

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 复制配置文件
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf

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
    /var/www/html/bootstrap/cache \
    /var/log/php-fpm

# 设置目录所有权和权限
RUN chown -R www-data:www-data /var/www/html/ && \
    chmod -R 755 /var/www/html/ && \
    chmod -R 777 /var/www/html/storage/ \
    /var/www/html/bootstrap/cache/ \
    /var/log/php-fpm/

# 复制测试文件
COPY docker/test-redis.php /var/www/html/public/test-redis.php
COPY docker/debug.php /var/www/html/public/debug.php
COPY docker/simple-test.php /var/www/html/public/simple-test.php

# 确保测试文件可访问
RUN chmod 644 /var/www/html/public/test-redis.php \
    /var/www/html/public/debug.php \
    /var/www/html/public/simple-test.php

# 禁用 open_basedir 限制
RUN echo "open_basedir = none" > /usr/local/etc/php/conf.d/no-basedir.ini && \
    echo "disable_functions = none" >> /usr/local/etc/php/conf.d/no-basedir.ini && \
    echo "display_errors = On" >> /usr/local/etc/php/conf.d/display-errors.ini && \
    echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/display-errors.ini && \
    echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/display-errors.ini

EXPOSE 80

# 启动命令：详细的调试信息
CMD ["sh", "-c", "\
  echo '=== 环境检查开始 ===' && \
  echo 'PHP 版本:' && php -v && \
  echo '当前用户:' && whoami && \
  echo 'Redis 扩展状态:' && php -m | grep redis && \
  echo '目录权限:' && ls -la /var/www/html/ && \
  echo '存储目录详情:' && ls -la /var/www/html/storage/ && \
  echo 'Bootstrap 缓存目录:' && ls -la /var/www/html/bootstrap/cache/ && \
  echo '=== 测试文件权限 ===' && \
  touch /var/www/html/storage/test_write.log && echo '存储目录可写 ✓' || echo '存储目录不可写 ✗' && \
  touch /var/www/html/bootstrap/cache/test_write.log && echo '缓存目录可写 ✓' || echo '缓存目录不可写 ✗' && \
  echo '=== 启动应用 ===' && \
  php artisan migrate --force && \
  echo '应用启动完成' && \
  echo '调试页面可用:' && \
  echo '1. https://您的域名/simple-test.php' && \
  echo '2. https://您的域名/debug.php' && \
  echo '3. https://您的域名/test-redis.php' && \
  /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf\n\
"]
