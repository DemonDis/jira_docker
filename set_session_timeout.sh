#!/bin/bash

DB_CONTAINER="jira_8.0.2-db-1"  # Имя контейнера базы данных
DB_NAME="jiradb"
DB_USER="jira"
DB_PASS="jellyfish"
TIMEOUT_SECONDS=$((366 * 24 * 60 * 60))  # 366 дней в секундах

echo "=== Установка срока сессии Jira на 366 дней ==="
echo "Таймаут: $TIMEOUT_SECONDS секунд (366 дней)"

# Проверка существования записи
EXISTS=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COUNT(*) FROM propertyentry WHERE property_key = 'jira.session.timeout';" 2>/dev/null | tr -d ' ')

if [ "$EXISTS" = "0" ]; then
    echo "Запись не найдена. Создание новой..."
    
    # Получаем следующий ID
    NEXT_ID=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT COALESCE(MAX(id), 0) + 1 FROM propertyentry;" 2>/dev/null | tr -d ' ')
    
    # Создаем запись в propertyentry
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
    INSERT INTO propertyentry (id, entity_name, entity_id, property_key, type)
    VALUES ($NEXT_ID, 'jira.properties', 1, 'jira.session.timeout', 5);
    " 2>/dev/null
    
    # Создаем запись в propertystring
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
    INSERT INTO propertystring (id, propertyvalue)
    VALUES ($NEXT_ID, '$TIMEOUT_SECONDS');
    " 2>/dev/null
    
    echo "Запись создана (ID: $NEXT_ID)"
else
    echo "Запись найдена. Обновление..."
    
    # Получаем ID записи
    PROP_ID=$(docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -t -c "SELECT id FROM propertyentry WHERE property_key = 'jira.session.timeout';" 2>/dev/null | tr -d ' ')
    
    # Обновляем значение
    docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
    UPDATE propertystring SET propertyvalue = '$TIMEOUT_SECONDS' WHERE id = $PROP_ID;
    " 2>/dev/null
    
    echo "Запись обновлена (ID: $PROP_ID)"
fi

# Проверка результата
echo ""
echo "Проверка текущего значения:"
docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" -c "
SELECT pe.property_key, ps.propertyvalue 
FROM propertyentry pe 
JOIN propertystring ps ON pe.id = ps.id 
WHERE pe.property_key = 'jira.session.timeout';
" 2>/dev/null

echo ""
echo "Перезапуск Jira..."
docker-compose restart jira

echo "=== Готово! ==="
echo "Срок сессии установлен на 366 дней."
