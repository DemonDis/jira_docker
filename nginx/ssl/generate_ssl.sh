#!/bin/bash

# Скрипт генерации SSL-сертификатов для Jira
# Требуемые версии:
# - OpenSSL: >= 1.1.1

SSL_DIR="$(cd "$(dirname "$0")" && pwd)"
DAYS_VALID=365
KEY_FILE="$SSL_DIR/jira.key"
CRT_FILE="$SSL_DIR/jira.crt"

echo "=== Генерация SSL-сертификатов для Jira ==="

# Проверка наличия openssl
if ! command -v openssl &> /dev/null; then
    echo "Ошибка: OpenSSL не установлен!"
    echo "Установка: sudo apt install openssl"
    exit 1
fi

# Проверка версии OpenSSL
OPENSSL_VERSION=$(openssl version | awk '{print $2}')
echo "OpenSSL версия: $OPENSSL_VERSION"

# Создание RSA ключа и самоподписанного сертификата
echo "Генерация ключа и сертификата..."
openssl req -x509 -nodes -days $DAYS_VALID -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -out "$CRT_FILE" \
    -subj "/CN=localhost" \
    2>/dev/null

if [ $? -eq 0 ]; then
    echo "Сертификаты успешно созданы:"
    echo "  Ключ: $KEY_FILE"
    echo "  Сертификат: $CRT_FILE"
    echo "Срок действия: $DAYS_VALID дней"
    
    # Проверка сертификата
    echo ""
    echo "Информация о сертификате:"
    openssl x509 -in "$CRT_FILE" -noout -subject -dates
else
    echo "Ошибка при генерации сертификатов!"
    exit 1
fi

echo ""
echo "=== Готово! ==="
echo "Пересоберите контейнер nginx:"
echo "  docker-compose down"
echo "  docker-compose up -d --build"
