# Запуск Atlassian Jira 8 с помощью Docker

## Требуемые версии программ
| Программа | Минимальная версия | Примечание |
|-----------|-------------------|------------|
| Docker | >= 20.10 | Основной инструмент контейнеризации |
| Docker Compose | >= 1.29 | Или docker compose plugin >= 2.0 |
| PHP | >= 7.4 | Для генерации лицензионного ключа (atlassian-keygen.php) |

## Установка и проверка необходимых программ

### Docker
Установка на Ubuntu/Debian:
```bash
# Удаление старых версий
sudo apt remove docker docker-engine docker.io containerd runc

# Установка зависимостей
sudo apt update
sudo apt install ca-certificates curl gnupg lsb-release

# Добавление официального GPG ключа Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Добавление репозитория Docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Установка Docker Engine
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

Проверка версии:
```bash
docker --version
# Ожидаемый вывод: Docker version 20.10.x или новее
```

### Docker Compose
Если используется плагин Docker Compose v2 (рекомендуется, устанавливается вместе с Docker Engine):
```bash
docker compose version
# Ожидаемый вывод: Docker Compose version v2.0.0 или новее
```

Для старой версии Docker Compose v1:
```bash
sudo apt install docker-compose
docker-compose --version
# Ожидаемый вывод: docker-compose version 1.29.0 или новее
```

### PHP
Установка:
```bash
sudo apt update
sudo apt install php-cli
```

Проверка версии:
```bash
php --version
# Ожидаемый вывод: PHP 7.4.x или новее
```

### Python
Установка:
```bash
sudo apt update
sudo apt install python3
```

Проверка версии:
```bash
python3 --version
# Ожидаемый вывод: Python 3.6.x или новее
```

## Быстрый старт

### 1. Запуск контейнеров
```bash
docker-compose up -d
# или
docker compose up -d
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
- `lsa` (обычные пользователи)
- и т.д.

## Файлы

- `Dockerfile` — сборка образа Jira с патченым `atlassian-extras-3.2.jar`
- `docker-compose.yml` — конфигурация сервисов
- `atlassian-extras-3.2.jar` — модифицированный JAR для обхода проверки лицензии
- `atlassian-keygen.php` — генератор лицензионных ключей
- `license_key_jira.txt` — шаблон лицензии (нужно заменить Server ID)
- `create_users.sh` — скрипт массового создания пользователей

## Примечание

Инструкция предназначена для ознакомления и тестирования. Для production-использования приобретите официальную лицензию Atlassian.
