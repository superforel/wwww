#!/bin/bash
/usr/local/bin/docker-entrypoint.sh php-fpm & # Запуск PHP-FPM через стандартный entrypoint
php_pid=$! # Сохраняем PID процесса PHP
# Проверка наличия wp-cli.phar
if [ ! -f “/wp-cli-is-install” ]; then
    echo “wp-cli.phar не найден, скачиваем...”
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    if [ $? -eq 0 ]; then
        chmod +x wp-cli.phar
        mv wp-cli.phar /usr/local/bin/wp
        touch /wp-cli-is-install
        echo “wp-cli.phar успешно установлен.”
    else
        echo “Ошибка при скачивании wp-cli.phar”
        exit 1
    fi
else
    echo “wp-cli.phar уже установлен.”
fi
# Проверка наличия wp-config.php
if [ ! -f “./wp-config.php” ]; then
    echo “wp-config.php не найден, выполняем установку WordPress...”
    wp core install \
        --url=“${WORDPRESS_URL}” \
        --title=“${WORDPRESS_SITE}” \
        --admin_user=“${WORDPRESS_ADMIN_USERNAME}” \
        --admin_password=“${WORDPRESS_ADMIN_PASSWORD}” \
        --admin_email=“${WORDPRESS_ADMIN_EMAIL}” \
        --allow-root
else
    echo “wp-config.php уже существует, установка WordPress не требуется.”
fi
# Цикл проверки установки WordPress (wp core)
echo “Проверяем наличие установки WordPress...”
until wp core is-installed --allow-root; do
    echo “WordPress еще не установлен. Повторяем проверку через 5 секунд...”
    sleep 5
done
# Установка и активация плагина Redis Cache
wp plugin install redis-cache --activate --allow-root
wp redis enable --allow-root
# Держим контейнер активным, пока работает PHP
wait $php_pid