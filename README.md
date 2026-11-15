# Доска объявлений(Kubernetes)

[![hexlet-check](https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319/actions)

Разверните приложение в Managed Kubernetes в облаке. Кластер описывается в Terraform, приложение выкатывается Helm-чартом, а метрики, логи и секреты подключаются к кластеру.

Учебный проект Хекслета: https://ru.hexlet.io/programs/devops-engineer-from-scratch
Как это должно работать: https://asciinema.org/a/v4evn7XjCdou7Yh71IG0ljb0W

## Стек

- Docker: сборка и запуск Spring Boot + React в одном контейнере.
- GitHub Container Registry (GHCR): хранение образов.
- GitHub Actions: сборка, проверка контейнера и публикация в GHCR.
- Terraform и DigitalOcean: VPC/NAT, DOKS, Managed PostgreSQL, Spaces и Secrets Manager.

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

#### Автоматическая публикация через GitHub Actions

[Workflow](./.github/workflows/docker.yml) собирает образ из Dockerfile
этого репозитория, запускает контейнер и проверяет UI, API и readiness.
Публикация выполняется только после успешной проверки того же образа:

- Pull request в `main`: сборка и проверка.
- Push в `main`: публикация тегов `latest` и `sha-<полный SHA коммита>`.
- Push тега `v0.1.0`: публикация тегов `0.1.0` и `sha-<полный SHA коммита>`.
- Ручной запуск через Actions → Build and publish Docker image → Run workflow:
  сборка и проверка; для `main` также публикация `latest` и тега с SHA.

SHA в теге образа относится к коммиту текущего инфраструктурного репозитория.
Версия исходников приложения зафиксирована через `APP_REV` в Dockerfile.
Чтобы обновить приложение в CI, измените этот SHA и отправьте коммит.
Push в отдельный форк приложения сам по себе этот workflow не запускает.

Workflow использует автоматически выданный `GITHUB_TOKEN` с правом
`packages: write`: отдельный PAT и дополнительные секреты для CI не нужны.
Если пакет ранее создан вручную, предоставьте текущему репозиторию доступ
на запись в настройках пакета → Manage Actions access.
Видимость пакета настраивается отдельно, как описано ниже.
Подробнее: [публикация образов через GitHub Actions](https://docs.github.com/en/actions/tutorials/publish-packages/publish-docker-images).

#### Ручная публикация

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

## Инфраструктура DigitalOcean

Конфигурация находится в [terraform/](./terraform), команды — в [Makefile](./Makefile).
Создаются VPC/NAT, DOKS с одной нодой, Managed PostgreSQL, Spaces-бакет приложения
и Secrets Manager. Регион — `fra1`, worker — `s-2vcpu-4gb`, PostgreSQL — 17.
Ноды используют приватную сеть и NAT; база разрешает подключения только кластеру.
S3-ключ приложения ограничен его бакетом. State хранится в отдельном Spaces-бакете.

### Требования и аутентификация

Нужны аккаунт DigitalOcean с биллингом, Bash и GNU Make (Windows: WSL), Git,
[Terraform >= 1.11](https://developer.hashicorp.com/terraform/install),
[doctl](https://docs.digitalocean.com/reference/doctl/how-to/install/) и
[kubectl](https://kubernetes.io/docs/tasks/tools/).

```bash
doctl auth init --context hexlet
doctl auth switch --context hexlet
doctl account get
cp .env.example .env
```

При `auth init` введите DigitalOcean API token. В `.env` локально заполните
`DIGITALOCEAN_TOKEN`, `SPACES_ACCESS_KEY_ID` и `SPACES_SECRET_ACCESS_KEY`.
Для создания бакетов Spaces-ключу нужен Full access. Загрузите переменные:

```bash
set -a
source .env
set +a
```

Перед первым `apply` включите [Secrets Manager preview](https://docs.digitalocean.com/products/secrets-manager/overview/)
в панели DigitalOcean. Это аналог Lockbox; пока он управляется через официальный
API провайдером `magodo/restful`, так как в DigitalOcean provider нет его ресурса.

### Backend и создание инфраструктуры

Бакет состояния должен существовать до `init` основного проекта. Для его создания
используется [terraform/bootstrap/](./terraform/bootstrap) с локальным state:

```bash
cp terraform/bootstrap/terraform.tfvars.example terraform/bootstrap/terraform.tfvars
```

Задайте уникальное `state_bucket_name`, затем выполните:

```bash
make tf-bootstrap-init
make tf-bootstrap-plan
make tf-bootstrap-apply
make tf-backend-config
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
```

В основном `terraform.tfvars` задайте уникальное `app_bucket_name` и свой публичный
IP с маской `/32` в `api_server_allowed_cidrs` — для доступа через `kubectl`.
Размер и количество worker и параметры PostgreSQL также задаются в этом файле.

```bash
make tf-init
make tf-plan
make tf-apply
make tf-kubeconfig
export KUBECONFIG="$PWD/.local/kubeconfig.yaml"
kubectl get nodes
```

`apply` применяет сохранённый план; bootstrap-state сохраните в защищённом месте.
После истечения kubeconfig получите свежий через
`doctl kubernetes cluster kubeconfig save <cluster_id>`.

### Ручной запуск через GitHub Actions

После bootstrap в **Settings → Environments → infrastructure** добавьте Secrets
`DIGITALOCEAN_TOKEN`, `SPACES_ACCESS_KEY_ID`, `SPACES_SECRET_ACCESS_KEY` и Variables:

| Variable | Значение |
| --- | --- |
| `TF_STATE_BUCKET` | Имя созданного бакета состояния |
| `APP_BUCKET_NAME` | Уникальное имя бакета приложения |
| `KUBERNETES_API_ALLOWED_CIDRS` | JSON-массив своего публичного IP, например `["203.0.113.10/32"]` |

В **Actions → Terraform → Run workflow** выберите `main` и `plan` либо `apply`.
Workflow запускается вручную и использует те же credentials и backend.

### Outputs и подключение приложения

Outputs включают `cluster_id`, `node_pool_id`, чувствительные `kubeconfig`,
`kubernetes_token`, `postgres_connection`, `s3_access` и идентификатор
секрета `app_secret_id` в формате `регион/имя` — аналог ID Lockbox.
Просмотр: `make tf-output`; отдельные параметры БД: `terraform -chdir=terraform output -json postgres_connection`.
JDBC использует приватный адрес и `sslmode=verify-full`; CA из секрета
`POSTGRES_CA_CERT` нужно смонтировать в `/etc/postgresql/ca.crt` при развёртывании приложения.
Для выделенной учебной БД используется `doadmin`, чтобы Hibernate мог создать схему.
State и планы содержат секреты даже с `sensitive = true`; они, `.env` и локальные
параметры исключены через `.gitignore`. Оба `.terraform.lock.hcl` храните в Git.

---

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
