# GreenGo Docker Setup

Complete Docker environment for GreenGo dating app development and testing.

---

## 🎯 Overview

This Docker setup provides a complete local development environment including:

- **Firebase Emulators** - Auth, Firestore, Storage, Functions
- **PostgreSQL** - Additional backend database
- **Redis** - Caching and session management
- **Adminer** - Database management UI
- **Redis Commander** - Redis management UI
- **Nginx** - API Gateway and reverse proxy

---

## 📋 Prerequisites

- Docker Desktop installed
- Docker Compose v2.0+
- At least 4GB RAM allocated to Docker
- Ports 80, 443, 4000-9199 available

---

## 🚀 Quick Start

### 1. Setup Environment

```bash
cd docker
cp .env.example .env
# Edit .env with your configuration
```

### 2. Start All Services

```bash
docker-compose up -d
```

### 3. Stop All Services

```bash
docker-compose down
```

### 4. Stop and Remove Volumes (Clean State)

```bash
docker-compose down -v
```

---

## 📦 Services

### Firebase Emulators

**Container:** `greengo_firebase`

**Ports:**
- `4000` - Emulator UI
- `9099` - Authentication
- `8080` - Firestore
- `9199` - Storage
- `5001` - Cloud Functions
- `8085` - Pub/Sub
- `9000` - Realtime Database

**Access:**
- UI: http://localhost:4000
- Auth: http://localhost:9099
- Firestore: http://localhost:8080

**Features:**
- Data persistence (stored in `./firebase/data`)
- Auto-export on shutdown
- Auto-import on startup

### PostgreSQL Database

**Container:** `greengo_postgres`

**Ports:** `5432`

**Credentials:**
- User: `greengo`
- Password: `greengo_dev_password` (change in .env)
- Database: `greengo_db`

**Connection String:**
```
postgresql://greengo:greengo_dev_password@localhost:5432/greengo_db
```

**Features:**
- Pre-initialized schema (see `postgres/init.sql`)
- Health checks
- Data persistence

### Redis Cache

**Container:** `greengo_redis`

**Ports:** `6379`

**Credentials:**
- Password: `greengo_redis_password` (change in .env)

**Connection:**
```bash
redis-cli -h localhost -p 6379 -a greengo_redis_password
```

**Features:**
- AOF persistence
- Health checks

### Adminer (Database UI)

**Container:** `greengo_adminer`

**Ports:** `8081`

**Access:** http://localhost:8081

**Login:**
- System: PostgreSQL
- Server: postgres
- Username: greengo
- Password: greengo_dev_password
- Database: greengo_db

### Redis Commander (Redis UI)

**Container:** `greengo_redis_commander`

**Ports:** `8082`

**Access:** http://localhost:8082

**Features:**
- Browse keys
- Execute commands
- Monitor performance

### Nginx (API Gateway)

**Container:** `greengo_nginx`

**Ports:**
- `80` - HTTP
- `443` - HTTPS (when SSL configured)

**Routes:**
- `/firebase` → Firebase Emulator UI
- `/auth` → Firebase Auth API
- `/firestore` → Firestore API
- `/storage` → Storage API
- `/adminer` → Adminer UI
- `/health` → Health check

**Access:** http://localhost

---

## 🔧 Configuration

### Firebase Emulator

Edit `firebase/firebase.json` to configure:
- Port mappings
- Security rules
- Import/export settings

### PostgreSQL Schema

Edit `postgres/init.sql` to modify:
- Database schema
- Initial data
- Indexes

### Nginx Routes

Edit `nginx/nginx.conf` to configure:
- Routing rules
- SSL/TLS
- Rate limiting

---

## 💾 Data Persistence

All data is persisted in Docker volumes:

**Volumes:**
- `postgres_data` - PostgreSQL database
- `redis_data` - Redis data
- `./firebase/data` - Firebase emulator data

**Backup Data:**
```bash
# Backup Firebase data
docker cp greengo_firebase:/firebase/data ./backup/firebase_data

# Backup PostgreSQL
docker exec greengo_postgres pg_dump -U greengo greengo_db > backup/greengo_db.sql
```

**Restore Data:**
```bash
# Restore Firebase data
docker cp ./backup/firebase_data greengo_firebase:/firebase/data

# Restore PostgreSQL
docker exec -i greengo_postgres psql -U greengo greengo_db < backup/greengo_db.sql
```

---

## 🛠️ Development Workflow

### 1. Start Environment

```bash
cd docker
docker-compose up -d
```

### 2. Check Service Status

```bash
docker-compose ps
```

### 3. View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f firebase
docker-compose logs -f postgres
```

### 4. Connect Flutter App to Emulators

Update your Flutter app to use local emulators:

```dart
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // Connect to Firebase Emulators
  if (kDebugMode) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
    await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  }

  runApp(MyApp());
}
```

### 5. Access Services

- **Firebase UI:** http://localhost:4000
- **Database Admin:** http://localhost:8081
- **Redis Admin:** http://localhost:8082
- **API Gateway:** http://localhost

---

## 🐛 Troubleshooting

### Port Already in Use

```bash
# Find process using port
netstat -ano | findstr :4000

# Kill process
taskkill /PID <process_id> /F
```

### Container Won't Start

```bash
# Check logs
docker-compose logs firebase

# Rebuild container
docker-compose up -d --build firebase
```

### Clear All Data and Restart

```bash
docker-compose down -v
docker-compose up -d
```

### Firebase Emulator Not Accessible

Check firewall settings and ensure host is `0.0.0.0` in `firebase.json`

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgres

# Test connection
docker exec -it greengo_postgres psql -U greengo -d greengo_db
```

---

## 📊 Monitoring

### View Resource Usage

```bash
docker stats
```

### Check Service Health

```bash
# All services
docker-compose ps

# Specific service health
docker inspect greengo_postgres | grep Health -A 10
```

---

## 🔒 Security Notes

### Development Only

This setup is for **development only**. Do NOT use in production with these credentials.

### Change Default Passwords

Update these in `.env`:
- `POSTGRES_PASSWORD`
- `REDIS_PASSWORD`
- `JWT_SECRET`

### SSL/TLS

For HTTPS, add certificates to `nginx/ssl/` and update `nginx.conf`

---

## 🚀 Production Deployment

For production:

1. **Use managed services:**
   - Firebase Production
   - AWS RDS/Cloud SQL for PostgreSQL
   - AWS ElastiCache/Google Cloud Memorystore for Redis

2. **Secure credentials:**
   - Use secrets management (AWS Secrets Manager, GCP Secret Manager)
   - Enable SSL/TLS
   - Use strong passwords

3. **Monitoring:**
   - Enable application monitoring
   - Set up alerts
   - Configure log aggregation

---

## 📝 Commands Reference

| Command | Description |
|---------|-------------|
| `docker-compose up -d` | Start all services |
| `docker-compose down` | Stop all services |
| `docker-compose down -v` | Stop and remove volumes |
| `docker-compose ps` | List running containers |
| `docker-compose logs -f` | View logs (all services) |
| `docker-compose logs -f <service>` | View logs (specific service) |
| `docker-compose restart <service>` | Restart a service |
| `docker-compose build` | Rebuild all images |
| `docker-compose up -d --build` | Rebuild and start |
| `docker exec -it <container> bash` | Shell into container |

---

## 🔄 Updates

### Update Docker Images

```bash
docker-compose pull
docker-compose up -d
```

### Rebuild After Changes

```bash
docker-compose up -d --build
```

---

## 📚 Additional Resources

- [Firebase Emulator Documentation](https://firebase.google.com/docs/emulator-suite)
- [PostgreSQL Docker](https://hub.docker.com/_/postgres)
- [Redis Docker](https://hub.docker.com/_/redis)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

---

## 🆘 Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Verify configuration in `.env`
3. Ensure all ports are available
4. Check Docker Desktop is running

---

**Last Updated:** November 2025
**Version:** 1.0.0
