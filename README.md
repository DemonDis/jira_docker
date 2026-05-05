# Запуск Atlassian Jira 8 с помощью Docker

## Требования
- Docker и Docker Compose
- PHP (для генерации лицензионного ключа)

## Быстрый старт

### 1. Запуск контейнеров
```bash
docker-compose up -d
```

Запустятся три сервиса:
- **Jira** — http://localhost:8080
- **PostgreSQL** — база данных
- **pgAdmin** — http://localhost:5050 (admin@example.com / admin)

### 2. Активация Jira

1. Откройте http://localhost:8080
2. Пройдите первоначальную настройку
3. Скопируйте **Server ID** (на экране лицензии)
4. Обновите Server ID в файле `license_key_jira.txt`
5. Сгенерируйте ключ:
   ```bash
   php atlassian-keygen.php -e license_key_jira.txt
   ```
6. Скопируйте сгенерированный ключ и вставьте в веб-интерфейс Jira

### 3. Подключение базы данных в pgAdmin

1. Откройте http://localhost:5050
2. Логин: `admin@example.com`, пароль: `admin`
3. Правой кнопкой на **Servers** → **Create** → **Server...**
4. Вкладка **General**: Name — `Jira DB`
5. Вкладка **Connection**:
   - Host: `db`
   - Port: `5432`
   - Database: `jiradb`
   - Username: `jira`
   - Password: `jellyfish`
6. Нажмите **Save**

### 4. Создание пользователей

Скрипт `create_users.sh` создаёт администратора и несколько тестовых пользователей.

Отредактируйте переменные в начале скрипта:
```bash
ADMIN_USER="sdd"      # ваш логин администратора
ADMIN_PASS="123" # ваш пароль администратора
```

Запуск:
```bash
chmod +x create_users.sh
./create_users.sh
```

Будут созданы:
- `superadmin` / `superadmin123` (администратор)
- `lsa` (обычные пользователи)

## Файлы

- `Dockerfile` — сборка образа Jira с патченым `atlassian-extras-3.2.jar`
- `docker-compose.yml` — конфигурация сервисов
- `atlassian-extras-3.2.jar` — модифицированный JAR для обхода проверки лицензии
- `atlassian-keygen.php` — генератор лицензионных ключей
- `license_key_jira.txt` — шаблон лицензии (нужно заменить Server ID)
- `create_users.sh` — скрипт массового создания пользователей

## Примечание

Инструкция предназначена для ознакомления и тестирования. Для production-использования приобретите официальную лицензию Atlassian.
