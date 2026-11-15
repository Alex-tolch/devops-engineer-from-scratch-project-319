# Доска объявлений(Kubernetes)

[![hexlet-check](https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319/actions)

Разверните приложение в Managed Kubernetes в облаке. Кластер описывается в Terraform, приложение выкатывается Helm-чартом, а метрики, логи и секреты подключаются к кластеру.

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-engineer-from-scratch
Как это должно работать: https://asciinema.org/a/v4evn7XjCdou7Yh71IG0ljb0W

## Стек

- Docker: сборка и запуск Spring Boot + React в одном контейнере.
- GitHub Container Registry (GHCR): хранение образов.

## Установка

Нужны Git и запущенный Docker Engine с поддержкой Linux-контейнеров
(например, Docker Desktop).

```bash
git clone https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319.git
cd devops-engineer-from-scratch-project-319
```

## Использование

### Сборка образа

Все команды выполняются из корня этого репозитория.
[Dockerfile](./Dockerfile) скачивает исходники
[форка приложения](https://github.com/Alex-tolch/project-devops-deploy)
внутри стадии сборки. Локальный клон приложения не требуется.
React собирается через `npm ci` и включается в Spring Boot JAR;
финальный образ содержит JRE 27 и запускается от пользователя с UID 10001.
Java, Gradle и Node.js на хосте не нужны.

```bash
docker build -t ghcr.io/alex-tolch/project-devops-deploy:local .
```

В Dockerfile зафиксирован коммит приложения
`736c9efc5569650a60bb2823660a0ff73f39892e`.
Чтобы собрать другую версию, передайте полный SHA коммита:

```bash
docker build --build-arg APP_REV=<commit-sha> -t ghcr.io/alex-tolch/project-devops-deploy:local .
```

### Локальная проверка

```bash
docker run -d --name bulletin-board -p 127.0.0.1:8080:8080 -p 127.0.0.1:9090:9090 -e SPRING_PROFILES_ACTIVE=dev ghcr.io/alex-tolch/project-devops-deploy:local
docker logs -f bulletin-board
```

Дождитесь запуска Spring Boot. Выйдите из просмотра логов через Ctrl+C.
Откройте UI: <http://localhost:8080/>. Проверьте API и готовность:

```bash
curl --fail http://localhost:8080/api/bulletins
curl --fail http://localhost:9090/actuator/health/readiness
```

В PowerShell используйте `curl.exe` вместо `curl`.
API должен вернуть список объявлений, readiness — `"status":"UP"`.
Swagger UI доступен по адресу <http://localhost:8080/swagger-ui/index.html>.
Профиль `dev` использует H2 в памяти и тестовые данные;
данные теряются при перезапуске приложения.

Остановите и удалите тестовый контейнер:

```bash
docker stop bulletin-board
docker rm bulletin-board
```

Для профиля `prod` нужны PostgreSQL и настройки хранилища изображений.
Передавайте переменные через `--env-file`; список переменных приведён
в [README приложения](https://github.com/Alex-tolch/project-devops-deploy#environment-variables).
Параметры JVM передаются через `-e JAVA_OPTS="-Xms256m -Xmx512m"`.

### Публикация в GitHub Container Registry

Адрес образа: `ghcr.io/alex-tolch/project-devops-deploy`.
Публикуйте тот же образ, который проверили локально.

1. Создайте [personal access token (classic)](https://github.com/settings/tokens/new?scopes=write:packages)
   с правом `write:packages`.
2. Выполните вход; в поле Password вставьте токен:

   ```bash
   docker login ghcr.io -u Alex-tolch
   ```

   Для автоматизации используйте `--password-stdin`. В Bash при уже
   заданной переменной `CR_PAT`:

   ```bash
   printf '%s' "$CR_PAT" | docker login ghcr.io -u Alex-tolch --password-stdin
   ```

   В PowerShell при заданной переменной окружения `CR_PAT`:

   ```powershell
   $env:CR_PAT | docker login ghcr.io -u Alex-tolch --password-stdin
   ```

3. Присвойте проверенному образу тег версии и отправьте его:

   ```bash
   docker tag ghcr.io/alex-tolch/project-devops-deploy:local ghcr.io/alex-tolch/project-devops-deploy:0.1.0
   docker push ghcr.io/alex-tolch/project-devops-deploy:0.1.0
   docker tag ghcr.io/alex-tolch/project-devops-deploy:0.1.0 ghcr.io/alex-tolch/project-devops-deploy:latest
   docker push ghcr.io/alex-tolch/project-devops-deploy:latest
   ```

   Для следующих релизов выбирайте новый версионный тег.
   Метка `org.opencontainers.image.source` связывает пакет с текущим
   репозиторием, где находится Dockerfile.
4. Откройте пакет в [GitHub Packages](https://github.com/Alex-tolch?tab=packages).
   Новый пакет по умолчанию приватный. Для скачивания без авторизации
   в настройках пакета выберите Change visibility → Public.
5. Проверьте скачивание опубликованной версии:

   ```bash
   docker pull ghcr.io/alex-tolch/project-devops-deploy:0.1.0
   docker logout ghcr.io
   ```

Для запуска скачанного образа используйте команду `docker run` выше
с тегом `0.1.0` вместо `local`.

Справка: [аутентификация, push и видимость пакетов GHCR](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
