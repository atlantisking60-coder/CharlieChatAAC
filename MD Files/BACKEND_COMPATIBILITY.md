# Backend Compatibility Architecture

## Overview

This document provides a comprehensive backend architecture for Charlie Chat that supports Android, iOS, Web, Windows, and macOS clients with authentication, user profiles, board sharing, backup, sync, and analytics.

---

## 1. Technology Stack

### Backend Framework
- **Node.js** with **Express** or **Fastify** (JavaScript/TypeScript)
  - Cross-platform compatibility
  - Excellent ecosystem
  - Easy to deploy
  - Good performance

### Database
- **PostgreSQL** - Primary database (relational data)
- **Redis** - Caching and session storage
- **S3/Cloud Storage** - File storage (boards, images, backups)

### Authentication
- **JWT (JSON Web Tokens)** - Stateless authentication
- **OAuth 2.0** - Third-party authentication (Google, Apple)
- **bcrypt** - Password hashing

### API
- **REST API** - Primary API interface
- **WebSocket** - Real-time sync (optional)
- **GraphQL** - Alternative for complex queries (optional)

### Deployment
- **Docker** - Containerization
- **Kubernetes** - Orchestration (optional)
- **AWS/GCP/Azure** - Cloud provider

---

## 2. API Design

### REST API Endpoints

#### Authentication

```
POST   /api/auth/register          - Register new user
POST   /api/auth/login             - Login user
POST   /api/auth/logout            - Logout user
POST   /api/auth/refresh           - Refresh access token
POST   /api/auth/forgot-password   - Request password reset
POST   /api/auth/reset-password    - Reset password
POST   /api/auth/verify-email      - Verify email address
POST   /api/auth/oauth/google      - OAuth with Google
POST   /api/auth/oauth/apple       - OAuth with Apple
```

#### User Profiles

```
GET    /api/users/me               - Get current user profile
PUT    /api/users/me               - Update current user profile
GET    /api/users/:id              - Get user by ID (public profile)
GET    /api/users/me/settings      - Get user settings
PUT    /api/users/me/settings      - Update user settings
DELETE /api/users/me               - Delete account
```

#### Boards

```
GET    /api/boards                 - List user's boards
POST   /api/boards                 - Create new board
GET    /api/boards/:id             - Get board by ID
PUT    /api/boards/:id             - Update board
DELETE /api/boards/:id             - Delete board
POST   /api/boards/:id/share       - Share board with user
DELETE /api/boards/:id/share/:userId - Unshare board
GET    /api/boards/:id/versions    - Get board versions
POST   /api/boards/:id/restore    - Restore board version
```

#### Sync

```
GET    /api/sync/status            - Get sync status
POST   /api/sync/push              - Push local changes
GET    /api/sync/pull              - Pull remote changes
GET    /api/sync/changes           - Get change log
POST   /api/sync/resolve           - Resolve conflict
```

#### Backup

```
GET    /api/backups                - List backups
POST   /api/backups                - Create backup
GET    /api/backups/:id            - Get backup by ID
DELETE /api/backups/:id            - Delete backup
POST   /api/backups/:id/restore    - Restore from backup
GET    /api/backups/:id/download   - Download backup
```

#### Analytics

```
POST   /api/analytics/events       - Track analytics event
GET    /api/analytics/summary      - Get analytics summary
GET    /api/analytics/boards       - Get board analytics
GET    /api/analytics/users         - Get user analytics
```

### API Response Format

```typescript
// Success Response
{
  "success": true,
  "data": {
    // Response data
  },
  "meta": {
    "timestamp": "2026-06-23T10:00:00Z",
    "requestId": "uuid"
  }
}

// Error Response
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable error message",
    "details": {}
  },
  "meta": {
    "timestamp": "2026-06-23T10:00:00Z",
    "requestId": "uuid"
  }
}

// Paginated Response
{
  "success": true,
  "data": [],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "totalPages": 5
  },
  "meta": {
    "timestamp": "2026-06-23T10:00:00Z",
    "requestId": "uuid"
  }
}
```

### API Versioning

```
/api/v1/...  - Current version
/api/v2/...  - Future version (backward compatible)
```

---

## 3. Database Design

### PostgreSQL Schema

#### Users Table

```sql
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  username VARCHAR(100) UNIQUE NOT NULL,
  display_name VARCHAR(255),
  avatar_url VARCHAR(500),
  email_verified BOOLEAN DEFAULT false,
  is_active BOOLEAN DEFAULT true,
  is_admin BOOLEAN DEFAULT false,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  last_login_at TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);
```

#### User Settings Table

```sql
CREATE TABLE user_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  theme_mode VARCHAR(20) DEFAULT 'system',
  voice_rate DECIMAL(3,2) DEFAULT 0.50,
  voice_pitch DECIMAL(3,2) DEFAULT 1.00,
  voice_volume DECIMAL(3,2) DEFAULT 1.00,
  voice_language VARCHAR(10) DEFAULT 'en-GB',
  voice_name VARCHAR(255) DEFAULT 'Google UK English Female',
  sentence_size VARCHAR(20) DEFAULT 'medium',
  sentence_type VARCHAR(20) DEFAULT 'both',
  read_sentence_only BOOLEAN DEFAULT false,
  font_size VARCHAR(20) DEFAULT 'medium',
  high_contrast BOOLEAN DEFAULT false,
  project_root VARCHAR(500),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id)
);

CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);
```

#### Boards Table

```sql
CREATE TABLE boards (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  rows INTEGER DEFAULT 6,
  columns INTEGER DEFAULT 5,
  adjustable_layout BOOLEAN DEFAULT false,
  box_scale DECIMAL(3,2) DEFAULT 1.00,
  tile_height DECIMAL(10,2) DEFAULT 100.00,
  tile_width DECIMAL(10,2) DEFAULT 100.00,
  background_color VARCHAR(20) DEFAULT 'transparent',
  is_sub_board BOOLEAN DEFAULT false,
  is_public BOOLEAN DEFAULT false,
  version INTEGER DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  deleted_at TIMESTAMP
);

CREATE INDEX idx_boards_user_id ON boards(user_id);
CREATE INDEX idx_boards_name ON boards(name);
CREATE INDEX idx_boards_is_public ON boards(is_public);
CREATE INDEX idx_boards_deleted_at ON boards(deleted_at);
```

#### Symbol Tiles Table

```sql
CREATE TABLE symbol_tiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  label VARCHAR(255) NOT NULL,
  category VARCHAR(255),
  image_asset VARCHAR(500),
  emoji VARCHAR(10),
  linked_board_id UUID,
  is_board_link BOOLEAN DEFAULT false,
  tile_size DECIMAL(3,2) DEFAULT 1.00,
  bg_color VARCHAR(20) DEFAULT 'transparent',
  text_color VARCHAR(20) DEFAULT '#000000',
  custom_voice VARCHAR(500),
  position INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_symbol_tiles_board_id ON symbol_tiles(board_id);
CREATE INDEX idx_symbol_tiles_category ON symbol_tiles(category);
CREATE INDEX idx_symbol_tiles_position ON symbol_tiles(position);
```

#### Board Shares Table

```sql
CREATE TABLE board_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  board_id UUID NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
  shared_with_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  shared_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  permission VARCHAR(20) DEFAULT 'view', -- view, edit
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(board_id, shared_with_user_id)
);

CREATE INDEX idx_board_shares_board_id ON board_shares(board_id);
CREATE INDEX idx_board_shares_shared_with_user_id ON board_shares(shared_with_user_id);
```

#### Sync Records Table

```sql
CREATE TABLE sync_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  entity_type VARCHAR(50) NOT NULL,
  entity_id VARCHAR(255) NOT NULL,
  operation VARCHAR(20) NOT NULL,
  payload JSONB NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  local_revision BIGINT NOT NULL,
  base_remote_revision BIGINT,
  status VARCHAR(20) DEFAULT 'pending',
  conflict_resolution VARCHAR(20),
  error_message TEXT,
  remote_payload JSONB
);

CREATE INDEX idx_sync_records_user_id ON sync_records(user_id);
CREATE INDEX idx_sync_records_status ON sync_records(status);
CREATE INDEX idx_sync_records_entity_type ON sync_records(entity_type);
CREATE INDEX idx_sync_records_entity_id ON sync_records(entity_id);
```

#### Backups Table

```sql
CREATE TABLE backups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  file_url VARCHAR(500) NOT NULL,
  file_size BIGINT,
  board_count INTEGER,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_backups_user_id ON backups(user_id);
CREATE INDEX idx_backups_created_at ON backups(created_at);
```

#### Analytics Events Table

```sql
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  event_type VARCHAR(100) NOT NULL,
  event_data JSONB,
  platform VARCHAR(50),
  app_version VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_event_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);
```

#### Refresh Tokens Table

```sql
CREATE TABLE refresh_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token VARCHAR(500) UNIQUE NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  revoked_at TIMESTAMP
);

CREATE INDEX idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);
```

---

## 4. Security Model

### Authentication Flow

```
┌─────────┐
│  Client │
└────┬────┘
     │
     │ POST /api/auth/login
     │ { email, password }
     ↓
┌─────────┐
│  Server │
└────┬────┘
     │
     │ 1. Validate credentials
     │ 2. Generate access token (JWT)
     │ 3. Generate refresh token
     │ 4. Store refresh token in DB
     ↓
┌─────────┐
│  Client │
└────┬────┘
     │
     │ Store tokens
     │ Use access token for API calls
     │ Use refresh token to get new access token
```

### JWT Token Structure

```typescript
// Access Token (15 minutes)
{
  "sub": "user-id",
  "email": "user@example.com",
  "role": "user",
  "iat": 1234567890,
  "exp": 1234568790
}

// Refresh Token (7 days)
{
  "sub": "user-id",
  "type": "refresh",
  "iat": 1234567890,
  "exp": 1235172590
}
```

### Password Security

```typescript
// Hash password with bcrypt
const saltRounds = 10;
const hashedPassword = await bcrypt.hash(password, saltRounds);

// Verify password
const isValid = await bcrypt.compare(password, hashedPassword);
```

### API Security

#### Rate Limiting

```typescript
// Rate limit by user
const rateLimit = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // 100 requests per window
  keyGenerator: (req) => req.user?.id || req.ip
});

// Rate limit by IP
const ipRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 50,
  keyGenerator: (req) => req.ip
});
```

#### Input Validation

```typescript
// Validate email
const emailSchema = z.string().email();

// Validate password
const passwordSchema = z.string()
  .min(8, 'Password must be at least 8 characters')
  .regex(/[A-Z]/, 'Password must contain uppercase letter')
  .regex(/[a-z]/, 'Password must contain lowercase letter')
  .regex(/[0-9]/, 'Password must contain number');

// Validate board name
const boardNameSchema = z.string()
  .min(1, 'Board name is required')
  .max(255, 'Board name too long');
```

#### CORS Configuration

```typescript
const corsOptions = {
  origin: process.env.ALLOWED_ORIGINS?.split(',') || [
    'http://localhost:3000',
    'https://charliechat.app'
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  allowedHeaders: ['Content-Type', 'Authorization']
};
```

### Data Encryption

```typescript
// Encrypt sensitive data at rest
import crypto from 'crypto';

const algorithm = 'aes-256-gcm';
const key = crypto.scryptSync(process.env.ENCRYPTION_KEY, 'salt', 32);
const iv = crypto.randomBytes(16);

function encrypt(text: string): string {
  const cipher = crypto.createCipheriv(algorithm, key, iv);
  let encrypted = cipher.update(text, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return `${iv.toString('hex')}:${encrypted}`;
}

function decrypt(encrypted: string): string {
  const [ivHex, encryptedText] = encrypted.split(':');
  const decipher = crypto.createDecipheriv(algorithm, key, Buffer.from(ivHex, 'hex'));
  let decrypted = decipher.update(encryptedText, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}
```

### OAuth 2.0 Integration

```typescript
// Google OAuth
const googleOAuth = new OAuth2Client({
  clientId: process.env.GOOGLE_CLIENT_ID,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET,
  redirectUri: process.env.GOOGLE_REDIRECT_URI
});

// Apple OAuth
const appleOAuth = new OAuth2Client({
  clientId: process.env.APPLE_CLIENT_ID,
  clientSecret: process.env.APPLE_CLIENT_SECRET,
  redirectUri: process.env.APPLE_REDIRECT_URI
});
```

---

## 5. Deployment Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Load Balancer                        │
│                   (AWS ALB / GCP LB)                        │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      API Gateway                            │
│                   (AWS API Gateway / Kong)                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                  Application Servers                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   Server 1   │  │   Server 2   │  │   Server 3   │  │
│  │   (Node.js)  │  │   (Node.js)  │  │   (Node.js)  │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ PostgreSQL   │  │    Redis     │  │   S3/Cloud   │  │
│  │   (Primary)  │  │   (Cache)    │  │   (Files)    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Docker Configuration

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["node", "dist/server.js"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - DATABASE_URL=postgresql://user:pass@postgres:5432/charliechat
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=your-secret
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=charliechat
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
```

### Kubernetes Deployment

```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: charliechat-api
spec:
  replicas: 3
  selector:
    matchLabels:
      app: charliechat-api
  template:
    metadata:
      labels:
        app: charliechat-api
    spec:
      containers:
      - name: api
        image: charliechat/api:latest
        ports:
        - containerPort: 3000
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: charliechat-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            secretKeyRef:
              name: charliechat-secrets
              key: redis-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: charliechat-api
spec:
  selector:
    app: charliechat-api
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

### CI/CD Pipeline

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm test
      - run: npm run lint

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - run: docker build -t charliechat/api:${{ github.sha }} .
      - run: docker push charliechat/api:${{ github.sha }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: azure/k8s-deploy@v4
        with:
          manifests: |
            k8s/deployment.yaml
            k8s/service.yaml
          images: |
            charliechat/api:${{ github.sha }}
```

### Environment Variables

```bash
# .env
NODE_ENV=production
PORT=3000

# Database
DATABASE_URL=postgresql://user:pass@localhost:5432/charliechat

# Redis
REDIS_URL=redis://localhost:6379

# JWT
JWT_SECRET=your-super-secret-key
JWT_EXPIRES_IN=15m
REFRESH_TOKEN_EXPIRES_IN=7d

# OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=https://charliechat.app/auth/google/callback

APPLE_CLIENT_ID=your-apple-client-id
APPLE_CLIENT_SECRET=your-apple-client-secret
APPLE_REDIRECT_URI=https://charliechat.app/auth/apple/callback

# Cloud Storage
AWS_ACCESS_KEY_ID=your-access-key
AWS_SECRET_ACCESS_KEY=your-secret-key
AWS_REGION=us-east-1
S3_BUCKET=charliechat-backups

# CORS
CORS_ORIGIN=https://charliechat.app,https://www.charliechat.app

# Rate Limiting
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

---

## 6. API Implementation Examples

### Authentication Controller

```typescript
// src/controllers/auth.controller.ts
import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { prisma } from '../lib/database';

export class AuthController {
  async register(req: Request, res: Response) {
    try {
      const { email, password, username } = req.body;
      
      // Check if user exists
      const existingUser = await prisma.users.findUnique({
        where: { email }
      });
      
      if (existingUser) {
        return res.status(400).json({
          success: false,
          error: {
            code: 'USER_EXISTS',
            message: 'User already exists'
          }
        });
      }
      
      // Hash password
      const passwordHash = await bcrypt.hash(password, 10);
      
      // Create user
      const user = await prisma.users.create({
        data: {
          email,
          password_hash: passwordHash,
          username,
          display_name: username
        }
      });
      
      // Generate tokens
      const accessToken = this.generateAccessToken(user.id);
      const refreshToken = this.generateRefreshToken(user.id);
      
      // Store refresh token
      await prisma.refresh_tokens.create({
        data: {
          user_id: user.id,
          token: refreshToken,
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
      });
      
      res.json({
        success: true,
        data: {
          user: this.sanitizeUser(user),
          accessToken,
          refreshToken
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  async login(req: Request, res: Response) {
    try {
      const { email, password } = req.body;
      
      // Find user
      const user = await prisma.users.findUnique({
        where: { email },
        include: { user_settings: true }
      });
      
      if (!user) {
        return res.status(401).json({
          success: false,
          error: {
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid email or password'
          }
        });
      }
      
      // Verify password
      const isValid = await bcrypt.compare(password, user.password_hash);
      
      if (!isValid) {
        return res.status(401).json({
          success: false,
          error: {
            code: 'INVALID_CREDENTIALS',
            message: 'Invalid email or password'
          }
        });
      }
      
      // Update last login
      await prisma.users.update({
        where: { id: user.id },
        data: { last_login_at: new Date() }
      });
      
      // Generate tokens
      const accessToken = this.generateAccessToken(user.id);
      const refreshToken = this.generateRefreshToken(user.id);
      
      // Store refresh token
      await prisma.refresh_tokens.create({
        data: {
          user_id: user.id,
          token: refreshToken,
          expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)
        }
      });
      
      res.json({
        success: true,
        data: {
          user: this.sanitizeUser(user),
          accessToken,
          refreshToken
        }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  private generateAccessToken(userId: string): string {
    return jwt.sign(
      { sub: userId },
      process.env.JWT_SECRET!,
      { expiresIn: '15m' }
    );
  }

  private generateRefreshToken(userId: string): string {
    return jwt.sign(
      { sub: userId, type: 'refresh' },
      process.env.JWT_SECRET!,
      { expiresIn: '7d' }
    );
  }

  private sanitizeUser(user: any) {
    const { password_hash, ...sanitized } = user;
    return sanitized;
  }
}
```

### Boards Controller

```typescript
// src/controllers/boards.controller.ts
export class BoardsController {
  async getBoards(req: Request, res: Response) {
    try {
      const userId = req.user.id;
      
      const boards = await prisma.boards.findMany({
        where: {
          user_id: userId,
          deleted_at: null
        },
        include: {
          symbol_tiles: {
            orderBy: { position: 'asc' }
          }
        },
        orderBy: { updated_at: 'desc' }
      });
      
      res.json({
        success: true,
        data: boards
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  async createBoard(req: Request, res: Response) {
    try {
      const userId = req.user.id;
      const boardData = req.body;
      
      const board = await prisma.boards.create({
        data: {
          ...boardData,
          user_id: userId
        }
      });
      
      res.json({
        success: true,
        data: board
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  async shareBoard(req: Request, res: Response) {
    try {
      const { id } = req.params;
      const { userId: sharedWithUserId, permission } = req.body;
      const currentUserId = req.user.id;
      
      // Check if user owns the board
      const board = await prisma.boards.findUnique({
        where: { id }
      });
      
      if (board?.user_id !== currentUserId) {
        return res.status(403).json({
          success: false,
          error: {
            code: 'FORBIDDEN',
            message: 'You do not own this board'
          }
        });
      }
      
      // Create share
      const share = await prisma.board_shares.create({
        data: {
          board_id: id,
          shared_with_user_id: sharedWithUserId,
          shared_by_user_id: currentUserId,
          permission: permission || 'view'
        }
      });
      
      res.json({
        success: true,
        data: share
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }
}
```

### Sync Controller

```typescript
// src/controllers/sync.controller.ts
export class SyncController {
  async push(req: Request, res: Response) {
    try {
      const userId = req.user.id;
      const changes = req.body.changes;
      
      const results = [];
      
      for (const change of changes) {
        const { entity_type, entity_id, operation, payload } = change;
        
        // Check for conflicts
        const existingRecord = await prisma.sync_records.findFirst({
          where: {
            user_id: userId,
            entity_id,
            status: 'pending'
          }
        });
        
        if (existingRecord) {
          // Conflict detected
          results.push({
            entity_id,
            conflict: true,
            remoteData: existingRecord.payload
          });
          continue;
        }
        
        // Apply change
        await this.applyChange(entity_type, entity_id, operation, payload, userId);
        
        // Record sync
        await prisma.sync_records.create({
          data: {
            user_id: userId,
            entity_type,
            entity_id,
            operation,
            payload,
            local_revision: Date.now(),
            status: 'synced'
          }
        });
        
        results.push({ entity_id, conflict: false });
      }
      
      res.json({
        success: true,
        data: { results }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  async pull(req: Request, res: Response) {
    try {
      const userId = req.user.id;
      const { since } = req.query;
      
      const sinceDate = since ? new Date(since as string) : new Date(0);
      
      const changes = await prisma.sync_records.findMany({
        where: {
          user_id: userId,
          updated_at: { gte: sinceDate }
        },
        orderBy: { updated_at: 'asc' }
      });
      
      res.json({
        success: true,
        data: { changes }
      });
    } catch (error) {
      res.status(500).json({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: error.message
        }
      });
    }
  }

  private async applyChange(
    entityType: string,
    entityId: string,
    operation: string,
    payload: any,
    userId: string
  ) {
    switch (entityType) {
      case 'board':
        await this.applyBoardChange(entityId, operation, payload, userId);
        break;
      case 'symbol_tile':
        await this.applyTileChange(entityId, operation, payload, userId);
        break;
      // Add other entity types
    }
  }

  private async applyBoardChange(
    id: string,
    operation: string,
    payload: any,
    userId: string
  ) {
    if (operation === 'upsert') {
      await prisma.boards.upsert({
        where: { id },
        create: { ...payload, user_id: userId },
        update: payload
      });
    } else if (operation === 'delete') {
      await prisma.boards.update({
        where: { id },
        data: { deleted_at: new Date() }
      });
    }
  }

  private async applyTileChange(
    id: string,
    operation: string,
    payload: any,
    userId: string
  ) {
    if (operation === 'upsert') {
      await prisma.symbol_tiles.upsert({
        where: { id },
        create: payload,
        update: payload
      });
    } else if (operation === 'delete') {
      await prisma.symbol_tiles.delete({
        where: { id }
      });
    }
  }
}
```

---

## 7. Monitoring & Logging

### Application Monitoring

```typescript
// Use Winston for logging
import winston from 'winston';

const logger = winston.createLogger({
  level: 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.File({ filename: 'error.log', level: 'error' }),
    new winston.transports.File({ filename: 'combined.log' })
  ]
});

// Use Prometheus for metrics
import promClient from 'prom-client';

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

// Use health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});
```

---

## 8. Summary

This backend architecture provides:

1. **Cross-Platform Support** - REST API works with all client platforms
2. **Authentication** - JWT with refresh tokens and OAuth 2.0
3. **User Profiles** - Complete user and settings management
4. **Board Sharing** - Share boards with permissions
5. **Backup** - Cloud backup and restore functionality
6. **Sync** - Bidirectional sync with conflict resolution
7. **Analytics** - Event tracking and analytics
8. **Security** - Rate limiting, input validation, encryption
9. **Scalability** - Docker and Kubernetes deployment
10. **Monitoring** - Logging, metrics, and health checks

---

**Related Documents:**
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)
- [UNIVERSAL_DATABASE.md](UNIVERSAL_DATABASE.md)
- [FLUTTER_UNIVERSAL_CLIENT.md](FLUTTER_UNIVERSAL_CLIENT.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
