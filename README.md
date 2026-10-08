# Server Resources Artifact

Shared infrastructure services for multi-tenant applications. This repository deploys PostgreSQL, Valkey (Redis), and RabbitMQ as platform-level services that other applications can connect to.

## Services

| Service | Image | Port | Purpose |
|---------|-------|------|---------|
| PostgreSQL | `postgres:15.7-alpine` | 5432 | Shared database server |
| Valkey | `valkey/valkey:7.2.11-alpine` | 6379 | Cache & pub/sub (Redis-compatible) |
| RabbitMQ | `rabbitmq:3.13.6-management-alpine` | 5672, 15672 | Message broker |

## Quick Start

### 1. Clone and Configure

```bash
git clone https://github.com/ridene-org/server-resources-artifact.git
cd server-resources-artifact
cp .env.example .env
```

Edit `.env` and change the default passwords:
```env
POSTGRES_PASSWORD=YourStrongPassword123!
RABBITMQ_PASS=YourStrongPassword123!
```

### 2. Deploy Locally

```bash
podman-compose up -d
podman-compose ps
```

### 3. Connect from Applications

**PostgreSQL:**
```
postgresql://platform_admin:YourStrongPassword123!@localhost:5432/your_app_db
```

**Valkey (Redis):**
```
redis://localhost:6379/0  # Use DB 0 for app1, DB 1 for app2, etc.
```

**RabbitMQ:**
```
amqp://platform_admin:YourStrongPassword123!@localhost:5672/your_app_vhost
```

## Multi-Tenant Setup

### PostgreSQL: Create Separate Databases
```sql
-- Connect as admin
psql -U platform_admin -h localhost

-- Create database for Plane
CREATE DATABASE plane_db;
CREATE USER plane_user WITH PASSWORD 'plane_password';
GRANT ALL PRIVILEGES ON DATABASE plane_db TO plane_user;

-- Create database for Next App
CREATE DATABASE nextapp_db;
CREATE USER nextapp_user WITH PASSWORD 'nextapp_password';
GRANT ALL PRIVILEGES ON DATABASE nextapp_db TO nextapp_user;
```

### RabbitMQ: Create Separate Vhosts
```bash
# Access management UI at http://localhost:15672
# Login: platform_admin / YourStrongPassword123!

# Or via CLI:
podman exec -it platform-rabbitmq rabbitmqctl add_vhost plane
podman exec -it platform-rabbitmq rabbitmqctl set_permissions -p plane plane_user ".*" ".*" ".*"
```

### Valkey: Use Different DB Indexes
- App 1: `redis://localhost:6379/0`
- App 2: `redis://localhost:6379/1`
- App 3: `redis://localhost:6379/2`

## Deployment to Server

### 1. Add GitHub Secrets
- `SERVER_HOST`: Your server IP/domain
- `SERVER_USER`: SSH username (e.g., `root`)
- `SERVER_SSH_KEY`: Your SSH private key

### 2. Trigger Deployment
Push to `main` branch or use **Actions → Deploy Platform Infrastructure → Run workflow**.

### 3. Verify on Server
```bash
ssh root@YOUR_SERVER_IP
podman-compose ps
podman-compose logs -f
```

## Resource Limits

Each service has resource limits defined in `docker-compose.yaml`:
- **PostgreSQL**: 1GB RAM, 1 CPU
- **Valkey**: 512MB RAM, 0.5 CPU
- **RabbitMQ**: 512MB RAM, 0.5 CPU

Adjust these based on your server capacity.

## Backup

### PostgreSQL
```bash
podman exec platform-postgres pg_dumpall -U platform_admin > backup.sql
```

### Valkey
```bash
podman exec platform-valkey valkey-cli BGSAVE
cp ~/.local/share/containers/storage/volumes/valkey-data/_data/dump.rdb ./backup.rdb
```

### RabbitMQ
```bash
podman exec platform-rabbitmq rabbitmqctl export_definitions /tmp/definitions.json
podman cp platform-rabbitmq:/tmp/definitions.json ./backup.json
```

## Troubleshooting

### Check Service Health
```bash
podman-compose ps
```

### View Logs
```bash
podman-compose logs -f postgres
podman-compose logs -f valkey
podman-compose logs -f rabbitmq
```

### Restart Services
```bash
podman-compose restart
```

### Reset Data (WARNING: Deletes all data!)
```bash
podman-compose down -v
podman-compose up -d
```

## Architecture

```
┌─────────────────────────────────────────────┐
│           Your Server (Host)                │
├─────────────────────────────────────────────┤
│  ┌──────────┐  ┌────────┐  ┌────────────┐  │
│  │PostgreSQL│  │ Valkey │  │  RabbitMQ  │  │
│  │ :5432    │  │ :6379  │  │ :5672/:15672│  │
│  └────┬─────┘  └───┬────┘  └─────┬──────┘  │
│       │            │             │          │
│  ┌────┴────────────┴─────────────┴──────┐   │
│  │       platform-network (bridge)      │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  External Apps connect via host ports       │
└─────────────────────────────────────────────┘
```

## License

MIT
