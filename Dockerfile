# Platform Infrastructure Dockerfile
# This Dockerfile is a reference for the services defined in docker-compose.yaml.
# Since we use official images, this file serves as documentation and can be
# used to build custom variants if needed (e.g., with custom extensions).

FROM postgres:15.7-alpine AS postgres-base
LABEL maintainer="Platform Team"
LABEL description="PostgreSQL 15 base image for platform infrastructure"

FROM valkey/valkey:7.2.11-alpine AS valkey-base
LABEL maintainer="Platform Team"
LABEL description="Valkey 7 base image for platform cache"

FROM rabbitmq:3.13.6-management-alpine AS rabbitmq-base
LABEL maintainer="Platform Team"
LABEL description="RabbitMQ 3 management base image for platform messaging"
