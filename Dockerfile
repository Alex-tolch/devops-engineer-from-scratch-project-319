# syntax=docker/dockerfile:1
ARG APP_REV=736c9efc5569650a60bb2823660a0ff73f39892e

FROM node:24-bookworm-slim AS source
RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/*
ARG APP_REV
WORKDIR /src
RUN git init . \
    && git remote add origin https://github.com/Alex-tolch/project-devops-deploy.git \
    && git fetch --depth=1 origin "$APP_REV" \
    && git checkout --detach FETCH_HEAD \
    && rm -rf .git

FROM node:24-bookworm-slim AS frontend
WORKDIR /app/frontend
COPY --from=source /src/frontend/package.json /src/frontend/package-lock.json ./
RUN npm ci
COPY --from=source /src/frontend/ ./
RUN npm run build

FROM eclipse-temurin:27-jdk AS backend
WORKDIR /app
COPY --from=source /src/gradlew /src/build.gradle.kts /src/settings.gradle.kts ./
COPY --from=source /src/gradle/ gradle/
RUN sed -i 's/\r$//' gradlew && chmod +x gradlew
COPY --from=source /src/src/ src/
COPY --from=frontend /app/frontend/dist/ src/main/resources/static/
RUN ./gradlew --no-daemon bootJar

FROM eclipse-temurin:27-jre
ARG APP_REV
LABEL org.opencontainers.image.source="https://github.com/Alex-tolch/devops-engineer-from-scratch-project-319" \
    org.opencontainers.image.revision="$APP_REV"
WORKDIR /app
COPY --from=backend --chown=10001:10001 /app/build/libs/*.jar app.jar
USER 10001:10001
EXPOSE 8080 9090
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
