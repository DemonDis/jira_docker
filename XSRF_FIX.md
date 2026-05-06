# Исправление ошибки XSRF в Jira за прокси-сервером

## Проблема
При создании проекта в Jira возникает ошибка "XSRF check failed". Это происходит из-за неправильной конфигурации Jira, работающей за nginx.

## Решение

### 1. Исправление docker-compose.yml

Добавьте переменные окружения для настройки прокси в сервис Jira:

```yaml
services:
  jira:
    build: ./jira
    ports:
      - "8080:8080"
    environment:
      - ATL_JDBC_URL=jdbc:postgresql://db:5432/jiradb
      - ATL_JDBC_USER=jira
      - ATL_JDBC_PASSWORD=jellyfish
      - ATL_DB_DRIVER=org.postgresql.Driver
      - ATL_DB_TYPE=postgres72
      - ATL_PROXY_NAME=192.168.xx.xx    # IP или домен вашего прокси
      - ATL_PROXY_PORT=443               # Порт прокси
      - ATL_TOMCAT_SCHEME=https          # Схема (http или https)
      - ATL_TOMCAT_SECURE=true           # true для https
    depends_on:
      - db
```

**Важно:** Убедитесь, что используется `ports` (множественное число), а не `port`.

### 2. Проверка конфигурации Tomcat (server.xml)

Внутри контейнера Jira файл `/opt/atlassian/jira/conf/server.xml` должен содержать правильные настройки в секции Connector:

```xml
<Connector port="8080"
           maxThreads="100"
           minSpareThreads="10"
           connectionTimeout="20000"
           enableLookups="false"
           protocol="HTTP/1.1"
           redirectPort="8443"
           acceptCount="10"
           secure="true"
           scheme="https"
           proxyName="192.168.xx.xx"
           proxyPort="443"
           ... />
```

Проверить текущую конфигурацию:
```bash
docker exec jira_docker-jira-1 cat /opt/atlassian/jira/conf/server.xml | grep -A 15 "Connector port"
```

### 3. Обновление базового URL в базе данных

Jira хранит базовый URL в базе данных. Если он не совпадает с адресом, по которому вы обращаетесь, возникнет ошибка XSRF.

Проверить текущий базовый URL:
```bash
docker exec jira_docker-db-1 psql -U jira -d jiradb -c "SELECT property_key, propertyvalue FROM propertystring ps JOIN propertyentry pe ON ps.id = pe.id WHERE pe.property_key = 'jira.baseurl';"
```

Обновить базовый URL (замените IP на ваш):
```bash
docker exec jira_docker-db-1 psql -U jira -d jiradb -c "UPDATE propertystring SET propertyvalue = 'https://192.168.xx.xx' WHERE id = (SELECT id FROM propertyentry WHERE property_key = 'jira.baseurl');"
```

### 4. Перезапуск контейнеров

После внесения изменений перезапустите контейнеры:

```bash
docker compose down
docker compose up -d
```

Или перезапустите только Jira:
```bash
docker restart jira_docker-jira-1
```

### 5. Ожидание загрузки

Jira может загружаться несколько минут. Проверить статус:
```bash
docker logs -f jira_docker-jira-1
```

## Проверка

После выполнения всех шагов откройте Jira по адресу https://192.168.xx.xx и попробуйте создать проект. Ошибка XSRF должна исчезнуть.

## Дополнительные настройки nginx

Убедитесь, что в nginx.conf правильно настроены заголовки:

```nginx
location / {
    proxy_pass http://jira:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
}
```

## Причина ошибки

XSRF (Cross-Site Request Forgery) токены генерируются на основе базового URL. Если Jira думает, что она работает на http://localhost, а вы обращаетесь по https://192.168.xx.xx, токены не совпадают и проверка не проходит.
