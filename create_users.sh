#!/bin/bash

JIRA="http://localhost:8080"
ADMIN_USER="sdd"
ADMIN_PASS="123"
COOKIE_JAR="/tmp/jira_cookies.txt"

echo "=== Создание пользователей в Jira ==="

# Проверка доступности Jira
echo "Проверка доступности Jira..."
until curl -s -o /dev/null -w "%{http_code}" "$JIRA/status" | grep -q "200\|302"; do
    echo "Ожидание запуска Jira..."
    sleep 10
done
echo "Jira доступна!"

# Получение сессии
echo "Авторизация..."
curl -s -c "$COOKIE_JAR" -X POST "$JIRA/rest/auth/1/session" \
  -H "Content-Type: application/json" \
  -d "{\"username\": \"$ADMIN_USER\", \"password\": \"$ADMIN_PASS\"}" -o /dev/null

# Получение CSRF токена
curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$JIRA/secure/Dashboard.jspa" -o /dev/null

# Создание администратора
echo "Создание администратора..."
curl -s -b "$COOKIE_JAR" -X POST "$JIRA/rest/api/2/user" \
  -H "Content-Type: application/json" \
  -H "X-Atlassian-Token: no-check" \
  -d '{
  "name": "superadmin",
  "password": "superadmin123",
  "emailAddress": "superadmin@example.com",
  "displayName": "Super Administrator"
}'

# Добавление в группу администраторов
curl -s -b "$COOKIE_JAR" -X POST "$JIRA/rest/api/2/group/user?groupname=jira-administrators" \
  -H "Content-Type: application/json" \
  -H "X-Atlassian-Token: no-check" \
  -d '{"name": "superadmin"}'

echo "Администратор superadmin создан"

# Создание обычных пользователей
USERS=(
  "lsa:lsa lsa:lsa@lsa.lsa"
)

for user in "${USERS[@]}"; do
  IFS=':' read -r username displayname email <<< "$user"
  echo "Создание пользователя: $username"
  curl -s -b "$COOKIE_JAR" -X POST "$JIRA/rest/api/2/user" \
    -H "Content-Type: application/json" \
    -H "X-Atlassian-Token: no-check" \
    -d "{
    \"name\": \"$username\",
    \"password\": \"$username\",
    \"emailAddress\": \"$email\",
    \"displayName\": \"$displayname\"
  }"
  echo ""
done

# Удаление cookie
rm -f "$COOKIE_JAR"

echo "=== Готово! ==="
echo "Созданные пользователи:"
echo "  superadmin / superadmin123 (администратор)"
for user in "${USERS[@]}"; do
  IFS=':' read -r username displayname email <<< "$user"
  echo "  $username / $username"
done
echo "Jira доступна!"

# Создание администратора
echo "Создание администратора..."
curl -s -X POST -H "Content-Type: application/json" -u "$ADMIN_USER:$ADMIN_PASS" \
  "$JIRA/rest/api/2/user" -d '{
  "name": "admin",
  "password": "123",
  "emailAddress": "superadmin@example.com",
  "displayName": "Super Administrator"
}'

# Добавление в группу администраторов
curl -s -X POST -H "Content-Type: application/json" -u "$ADMIN_USER:$ADMIN_PASS" \
  "$JIRA/rest/api/2/group/user?groupname=jira-administrators" \
  -d '{"name": "superadmin"}'

echo "Администратор superadmin создан"

# Создание обычных пользователей
USERS=(
  "lsa:lsa lsa:lsa@lsa.lsa"
)

for user in "${USERS[@]}"; do
  IFS=':' read -r username displayname email <<< "$user"
  echo "Создание пользователя: $username"
  curl -s -X POST -H "Content-Type: application/json" -u "$ADMIN_USER:$ADMIN_PASS" \
    "$JIRA/rest/api/2/user" -d "{
    \"name\": \"$username\",
    \"password\": \"$username\",
    \"emailAddress\": \"$email\",
    \"displayName\": \"$displayname\"
  }"
  echo ""
done

echo "=== Готово! ==="
echo "Созданные пользователи:"
echo "  superadmin / superadmin123 (администратор)"
for user in "${USERS[@]}"; do
  IFS=':' read -r username displayname email <<< "$user"
  echo "  $username / $username"
done
