# API Versioning Strategy

## Overview

This document provides a comprehensive API versioning strategy for Charlie Chat that ensures old clients remain functional while new clients gain features, with gradual migrations and clear deprecation policies.

---

## 1. Versioning Philosophy

### Principles

1. **Backward Compatibility** - Old clients continue to work without breaking changes
2. **Forward Compatibility** - New clients can use new features without affecting old clients
3. **Clear Communication** - Deprecation warnings and sunset dates are clearly communicated
4. **Gradual Migration** - Clients have time to migrate before features are removed
5. **Semantic Versioning** - Version numbers indicate the nature of changes

### Version Numbering Scheme

```
MAJOR.MINOR.PATCH

MAJOR    - Breaking changes (requires client update)
MINOR    - New backward-compatible features
PATCH    - Bug fixes, internal changes
```

**Examples:**
- `v1.0.0` → `v1.1.0` - New features, backward compatible
- `v1.1.0` → `v1.1.1` - Bug fix, backward compatible
- `v1.1.1` → `v2.0.0` - Breaking changes, requires migration

---

## 2. URL-Based Versioning

### Version Structure

```
/api/v{version}/{resource}

Examples:
/api/v1/boards
/api/v1/users/me
/api/v2/boards
/api/v2/users/me
```

### Version Routing

```typescript
// src/routes/version.routes.ts
import express from 'express';
import v1Routes from './v1';
import v2Routes from './v2';

const router = express.Router();

// Version routes
router.use('/v1', v1Routes);
router.use('/v2', v2Routes);

// Default to latest version
router.use('/', v2Routes);

export default router;
```

### Version Detection

```typescript
// src/middleware/version.middleware.ts
export function detectVersion(req: Request, res: Response, next: NextFunction) {
  const version = req.path.match(/\/v(\d+)\//)?.[1];
  
  if (version) {
    req.apiVersion = parseInt(version);
  } else {
    // Default to latest version
    req.apiVersion = LATEST_VERSION;
  }
  
  next();
}
```

---

## 3. Header-Based Versioning (Optional)

### Accept Header

```
Accept: application/vnd.charliechat.v1+json
Accept: application/vnd.charliechat.v2+json
```

### Custom Header

```
API-Version: 1
API-Version: 2
```

### Implementation

```typescript
// src/middleware/version.middleware.ts
export function detectVersionFromHeader(req: Request, res: Response, next: NextFunction) {
  const acceptHeader = req.headers['accept'];
  const apiVersionHeader = req.headers['api-version'];
  
  if (apiVersionHeader) {
    req.apiVersion = parseInt(apiVersionHeader as string);
  } else if (acceptHeader) {
    const match = acceptHeader.match(/vnd\.charliechat\.v(\d+)\+json/);
    if (match) {
      req.apiVersion = parseInt(match[1]);
    }
  } else {
    req.apiVersion = LATEST_VERSION;
  }
  
  next();
}
```

---

## 4. Version Lifecycle

### Lifecycle Stages

```
┌─────────────┐
│  Development│  - New features, unstable
└──────┬──────┘
       ↓
┌─────────────┐
│    Stable   │  - Production ready, default
└──────┬──────┘
       ↓
┌─────────────┐
│ Deprecated  │  - Warning header, sunset date
└──────┬──────┘
       ↓
┌─────────────┐
│  Sunset     │  - Removed from service
└─────────────┘
```

### Timeline

- **Development**: 0-3 months
- **Stable**: 6-12 months minimum
- **Deprecated**: 3-6 months warning period
- **Sunset**: After deprecation period

### Version Status

```typescript
// src/config/versions.ts
export const VERSION_STATUS = {
  v1: {
    status: 'deprecated',
    sunsetDate: '2026-12-31',
    migrationGuide: '/docs/migration-v1-to-v2'
  },
  v2: {
    status: 'stable',
    releaseDate: '2026-06-23',
    features: ['board-sharing', 'analytics', 'backup']
  },
  v3: {
    status: 'development',
    features: ['real-time-sync', 'ai-suggestions']
  }
};
```

---

## 5. Deprecation Policy

### Deprecation Process

1. **Announcement** - Notify developers via email, changelog, and API docs
2. **Warning Header** - Add deprecation header to API responses
3. **Grace Period** - Minimum 3 months before removal
4. **Monitoring** - Track usage of deprecated version
5. **Removal** - Remove after sunset date

### Deprecation Header

```typescript
// src/middleware/deprecation.middleware.ts
export function addDeprecationHeader(req: Request, res: Response, next: NextFunction) {
  const version = req.apiVersion;
  const versionInfo = VERSION_STATUS[`v${version}`];
  
  if (versionInfo?.status === 'deprecated') {
    res.setHeader('Deprecation', 'true');
    res.setHeader('Sunset', versionInfo.sunsetDate);
    res.setHeader('Link', `<${versionInfo.migrationGuide}>; rel="deprecation"`);
  }
  
  next();
}
```

### Deprecation Response

```typescript
// Example response for deprecated version
{
  "success": true,
  "data": { /* ... */ },
  "meta": {
    "version": "v1",
    "deprecation": {
      "warning": "This API version is deprecated and will be removed on 2026-12-31",
      "sunsetDate": "2026-12-31",
      "migrationGuide": "https://api.charliechat.app/docs/migration-v1-to-v2"
    }
  }
}
```

### Deprecation Email Template

```
Subject: API Version v1 Deprecation Notice

Dear Developer,

This is a notification that API version v1 will be deprecated and removed on 2026-12-31.

What you need to know:
- v1 will continue to work until the sunset date
- New features will only be available in v2
- We recommend migrating to v2 as soon as possible

Migration guide: https://api.charliechat.app/docs/migration-v1-to-v2

If you have questions, please contact api-support@charliechat.app

Best regards,
Charlie Chat API Team
```

---

## 6. Breaking Changes

### What Constitutes a Breaking Change

- **Required field changes** - Adding required fields to request/response
- **Field removal** - Removing fields from request/response
- **Field type changes** - Changing data types of existing fields
- **Endpoint removal** - Removing entire endpoints
- **HTTP method changes** - Changing GET to POST, etc.
- **Authentication changes** - Changing auth mechanism
- **Error response changes** - Changing error response structure

### Non-Breaking Changes

- **Adding optional fields** - New fields in response
- **Adding new endpoints** - New API endpoints
- **Adding new query parameters** - Optional parameters
- **Changing field order** - Order of fields in response
- **Adding new HTTP headers** - Optional headers
- **Performance improvements** - Faster responses

### Breaking Change Example

**v1 Response:**
```json
{
  "success": true,
  "data": {
    "id": "123",
    "name": "Board Name"
  }
}
```

**v2 Response (Breaking):**
```json
{
  "success": true,
  "data": {
    "id": "123",
    "name": "Board Name",
    "ownerId": "456"  // NEW REQUIRED FIELD
  }
}
```

### Non-Breaking Change Example

**v1 Response:**
```json
{
  "success": true,
  "data": {
    "id": "123",
    "name": "Board Name"
  }
}
```

**v2 Response (Non-Breaking):**
```json
{
  "success": true,
  "data": {
    "id": "123",
    "name": "Board Name",
    "createdAt": "2026-06-23T10:00:00Z"  // NEW OPTIONAL FIELD
  }
}
```

---

## 7. Version-Specific Implementations

### Adapter Pattern

```typescript
// src/adapters/board.adapter.ts
export interface BoardAdapter {
  serialize(board: Board): any;
  deserialize(data: any): Board;
}

export class V1BoardAdapter implements BoardAdapter {
  serialize(board: Board): any {
    return {
      id: board.id,
      name: board.name,
      rows: board.rows,
      columns: board.columns
    };
  }

  deserialize(data: any): Board {
    return {
      id: data.id,
      name: data.name,
      rows: data.rows,
      columns: data.columns,
      // Default values for new fields
      adjustableLayout: false,
      boxScale: 1.0
    };
  }
}

export class V2BoardAdapter implements BoardAdapter {
  serialize(board: Board): any {
    return {
      id: board.id,
      name: board.name,
      rows: board.rows,
      columns: board.columns,
      adjustableLayout: board.adjustableLayout,
      boxScale: board.boxScale
    };
  }

  deserialize(data: any): Board {
    return {
      id: data.id,
      name: data.name,
      rows: data.rows,
      columns: data.columns,
      adjustableLayout: data.adjustableLayout ?? false,
      boxScale: data.boxScale ?? 1.0
    };
  }
}
```

### Version-Specific Controllers

```typescript
// src/controllers/v1/boards.controller.ts
export class V1BoardsController {
  async getBoards(req: Request, res: Response) {
    const boards = await boardService.getBoards(req.user.id);
    const adapter = new V1BoardAdapter();
    
    const serialized = boards.map(board => adapter.serialize(board));
    
    res.json({
      success: true,
      data: serialized
    });
  }
}

// src/controllers/v2/boards.controller.ts
export class V2BoardsController {
  async getBoards(req: Request, res: Response) {
    const boards = await boardService.getBoards(req.user.id);
    const adapter = new V2BoardAdapter();
    
    const serialized = boards.map(board => adapter.serialize(board));
    
    res.json({
      success: true,
      data: serialized
    });
  }
}
```

### Version Factory

```typescript
// src/factories/version.factory.ts
export class VersionFactory {
  static getBoardAdapter(version: number): BoardAdapter {
    switch (version) {
      case 1:
        return new V1BoardAdapter();
      case 2:
        return new V2BoardAdapter();
      default:
        return new V2BoardAdapter(); // Default to latest
    }
  }
}
```

---

## 8. Migration Guide Template

### Migration Guide Structure

```markdown
# Migration Guide: v1 to v2

## Overview
This guide helps you migrate from API v1 to v2.

## Breaking Changes

### 1. Board Response Structure
**v1:**
```json
{
  "id": "123",
  "name": "Board Name"
}
```

**v2:**
```json
{
  "id": "123",
  "name": "Board Name",
  "ownerId": "456",
  "createdAt": "2026-06-23T10:00:00Z",
  "updatedAt": "2026-06-23T10:00:00Z"
}
```

**Action:** Update your code to handle new fields.

### 2. Authentication Header
**v1:**
```
Authorization: Bearer {token}
```

**v2:**
```
Authorization: Bearer {token}
X-API-Version: 2
```

**Action:** Add `X-API-Version` header.

## New Features

### Board Sharing
New endpoint for sharing boards:
```
POST /api/v2/boards/:id/share
```

### Analytics
New analytics endpoint:
```
POST /api/v2/analytics/events
```

## Code Examples

### JavaScript/TypeScript
```typescript
// Before (v1)
const response = await fetch('/api/v1/boards', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});

// After (v2)
const response = await fetch('/api/v2/boards', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'X-API-Version': '2'
  }
});
```

## Testing Checklist
- [ ] Update API base URL
- [ ] Add version header
- [ ] Update response parsing
- [ ] Test all endpoints
- [ ] Verify new features work

## Support
If you need help, contact api-support@charliechat.app
```

---

## 9. Version Monitoring

### Usage Tracking

```typescript
// src/services/version-monitor.service.ts
export class VersionMonitorService {
  async trackVersionUsage(req: Request) {
    const version = req.apiVersion;
    const endpoint = req.path;
    const userId = req.user?.id;
    
    await prisma.api_usage.create({
      data: {
        version,
        endpoint,
        user_id: userId,
        timestamp: new Date()
      }
    });
  }

  async getVersionStats(version: number) {
    const stats = await prisma.api_usage.groupBy({
      by: ['version'],
      where: { version },
      _count: true
    });
    
    return stats;
  }

  async getDeprecatedVersionUsage() {
    const deprecatedVersions = Object.entries(VERSION_STATUS)
      .filter(([_, info]) => info.status === 'deprecated')
      .map(([version]) => parseInt(version.replace('v', '')));
    
    const usage = await prisma.api_usage.groupBy({
      by: ['version'],
      where: {
        version: { in: deprecatedVersions }
      },
      _count: true
    });
    
    return usage;
  }
}
```

### Usage Dashboard

```typescript
// src/controllers/admin/version-stats.controller.ts
export class VersionStatsController {
  async getStats(req: Request, res: Response) {
    const stats = await versionMonitor.getVersionStats();
    const deprecatedUsage = await versionMonitor.getDeprecatedVersionUsage();
    
    res.json({
      success: true,
      data: {
        allVersions: stats,
        deprecatedVersions: deprecatedUsage,
        totalRequests: stats.reduce((sum, s) => sum + s._count, 0)
      }
    });
  }
}
```

### Alerts

```typescript
// src/services/alert.service.ts
export class AlertService {
  async checkDeprecatedUsage() {
    const deprecatedUsage = await versionMonitor.getDeprecatedVersionUsage();
    
    for (const usage of deprecatedUsage) {
      const count = usage._count;
      const version = usage.version;
      
      if (count > 1000) {
        // High usage of deprecated version
        await this.sendAlert({
          type: 'high_deprecated_usage',
          version,
          count,
          message: `Version v${version} has ${count} requests in the last hour`
        });
      }
    }
  }

  private async sendAlert(alert: any) {
    // Send to Slack, email, or monitoring service
  }
}
```

---

## 10. Client-Side Version Handling

### Version Detection

```typescript
// lib/services/api_version_service.dart
class ApiVersionService {
  static const String _baseUrl = 'https://api.charliechat.app';
  static const int _currentVersion = 2;
  
  static String get baseUrl => '$_baseUrl/v$_currentVersion';
  
  static Future<void> checkForUpdates() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/version-info'),
      headers: {'X-API-Version': _currentVersion.toString()},
    );
    
    final data = jsonDecode(response.body);
    final latestVersion = data['latestVersion'];
    
    if (latestVersion > _currentVersion) {
      _showUpdateNotification(latestVersion);
    }
  }
  
  static void _showUpdateNotification(int newVersion) {
    // Show notification to user
  }
}
```

### Version-Specific API Calls

```typescript
// lib/services/api_client.dart
class ApiClient {
  final int version;
  
  ApiClient({this.version = 2});
  
  Future<Map<String, dynamic>> getBoards() async {
    final response = await http.get(
      Uri.parse('https://api.charliechat.app/v$version/boards'),
      headers: {
        'Authorization': 'Bearer $token',
        'X-API-Version': version.toString(),
      },
    );
    
    return jsonDecode(response.body);
  }
}
```

### Fallback to Older Version

```typescript
// lib/services/api_client.dart
class ApiClient {
  Future<Map<String, dynamic>> getBoards() async {
    try {
      return await _getBoardsV2();
    } catch (e) {
      if (e is HttpException && e.statusCode == 400) {
        // Fallback to v1 if v2 fails
        return await _getBoardsV1();
      }
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> _getBoardsV2() async {
    final response = await http.get(
      Uri.parse('https://api.charliechat.app/v2/boards'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return jsonDecode(response.body);
  }
  
  Future<Map<String, dynamic>> _getBoardsV1() async {
    final response = await http.get(
      Uri.parse('https://api.charliechat.app/v1/boards'),
      headers: {'Authorization': 'Bearer $token'},
    );
    
    return jsonDecode(response.body);
  }
}
```

---

## 11. Documentation Strategy

### API Documentation

```typescript
// Use OpenAPI/Swagger for documentation
const swaggerSpec = {
  openapi: '3.0.0',
  info: {
    title: 'Charlie Chat API',
    version: '2.0.0',
    description: 'API for Charlie Chat AAC platform'
  },
  servers: [
    { url: 'https://api.charliechat.app/v1', description: 'API v1 (Deprecated)' },
    { url: 'https://api.charliechat.app/v2', description: 'API v2 (Current)' }
  ],
  paths: {
    '/boards': {
      get: {
        summary: 'Get all boards',
        tags: ['Boards'],
        responses: {
          '200': {
            description: 'Success',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/BoardList' }
              }
            }
          }
        }
      }
    }
  }
};
```

### Version-Specific Documentation

- **v1 Docs** - Archived at `/docs/api/v1`
- **v2 Docs** - Current at `/docs/api/v2`
- **Migration Guides** - `/docs/migration/v1-to-v2`

### Changelog

```markdown
# Changelog

## [2.0.0] - 2026-06-23

### Added
- Board sharing feature
- Analytics tracking
- Cloud backup
- Real-time sync (beta)

### Changed
- Board response includes `ownerId` field
- Authentication requires `X-API-Version` header

### Deprecated
- v1 API (sunset: 2026-12-31)

## [1.2.0] - 2026-03-15

### Added
- User profiles
- Board templates

### Fixed
- Fixed board sharing permissions

## [1.1.0] - 2026-01-10

### Added
- Symbol tiles
- Board categories

### Fixed
- Fixed authentication token refresh

## [1.0.0] - 2025-12-01

### Added
- Initial release
- Board CRUD operations
- User authentication
```

---

## 12. Testing Strategy

### Version-Specific Tests

```typescript
// tests/v1/boards.test.ts
describe('API v1 Boards', () => {
  it('should get boards', async () => {
    const response = await request(app)
      .get('/api/v1/boards')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    
    expect(response.body.data[0]).toHaveProperty('id');
    expect(response.body.data[0]).toHaveProperty('name');
    expect(response.body.data[0]).not.toHaveProperty('ownerId');
  });
});

// tests/v2/boards.test.ts
describe('API v2 Boards', () => {
  it('should get boards', async () => {
    const response = await request(app)
      .get('/api/v2/boards')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    
    expect(response.body.data[0]).toHaveProperty('id');
    expect(response.body.data[0]).toHaveProperty('name');
    expect(response.body.data[0]).toHaveProperty('ownerId');
  });
});
```

### Compatibility Tests

```typescript
// tests/compatibility.test.ts
describe('Version Compatibility', () => {
  it('v1 response should be parseable by v2 client', async () => {
    const v1Response = await request(app)
      .get('/api/v1/boards')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    
    // v2 client should handle v1 response
    const board = v1Response.body.data[0];
    expect(board.id).toBeDefined();
    expect(board.name).toBeDefined();
  });
  
  it('v2 response should include v1 fields', async () => {
    const v2Response = await request(app)
      .get('/api/v2/boards')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);
    
    const board = v2Response.body.data[0];
    expect(board.id).toBeDefined();
    expect(board.name).toBeDefined();
    // v2 specific fields
    expect(board.ownerId).toBeDefined();
  });
});
```

---

## 13. Rollback Strategy

### Emergency Rollback

```typescript
// src/services/rollback.service.ts
export class RollbackService {
  async rollbackToVersion(targetVersion: number) {
    // 1. Switch traffic to previous version
    await this.switchVersion(targetVersion);
    
    // 2. Notify monitoring
    await this.notifyRollback(targetVersion);
    
    // 3. Log rollback
    await this.logRollback(targetVersion);
  }
  
  private async switchVersion(version: number) {
    // Update load balancer configuration
    // Or update environment variable
  }
}
```

### Feature Flags

```typescript
// src/services/feature-flag.service.ts
export class FeatureFlagService {
  private flags = {
    v2_features: process.env.ENABLE_V2_FEATURES === 'true',
    real_time_sync: process.env.ENABLE_REAL_TIME_SYNC === 'true',
    analytics: process.env.ENABLE_ANALYTICS === 'true'
  };
  
  isEnabled(flag: string): boolean {
    return this.flags[flag] ?? false;
  }
}
```

---

## 14. Summary

This API versioning strategy provides:

1. **Backward Compatibility** - Old clients continue to work
2. **Clear Versioning** - URL-based versioning with semantic versioning
3. **Deprecation Policy** - Clear warnings and sunset dates
4. **Migration Support** - Comprehensive migration guides
5. **Monitoring** - Track version usage and deprecated endpoints
6. **Testing** - Version-specific and compatibility tests
7. **Documentation** - Version-specific docs and changelogs
8. **Rollback** - Emergency rollback capability
9. **Feature Flags** - Gradual feature rollout

---

**Related Documents:**
- [BACKEND_COMPATIBILITY.md](BACKEND_COMPATIBILITY.md)
- [CLEAN_ARCHITECTURE.md](CLEAN_ARCHITECTURE.md)

---

**Document Version:** 1.0  
**Last Updated:** June 2026
