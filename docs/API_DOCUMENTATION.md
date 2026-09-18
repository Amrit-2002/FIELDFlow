# FIELDFlow REST API Documentation

Base URL: `http://localhost:5000/api/v1`

All protected endpoints require an `Authorization: Bearer <accessToken>` HTTP header.

---

## 1. Authentication Endpoints

### `POST /auth/login`
Authenticates a technician and returns access and refresh tokens.

**Request:**
```json
{
  "email": "worker@example.com",
  "password": "password123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIs...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
      "id": "uuid-v4",
      "name": "Amrit Sharma",
      "email": "worker@example.com",
      "role": "FIELD_WORKER"
    }
  },
  "message": "Login successful"
}
```

### `POST /auth/refresh`
Issues a new access and refresh token pair.

**Request:**
```json
{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### `GET /auth/me`
Retrieves profile for the authenticated technician.

---

## 2. Task Endpoints

### `GET /tasks`
Retrieves a paginated list of assigned tasks with search and filtering.

**Query Parameters:**
- `page` (default: 1)
- `limit` (default: 20, max: 100)
- `status` (`ASSIGNED`, `ACCEPTED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`)
- `priority` (`LOW`, `MEDIUM`, `HIGH`, `URGENT`)
- `search` (searches title, customer name, and address)

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": "task-uuid",
        "title": "Commercial HVAC Airflow & Cooling Diagnostic",
        "customerName": "Apex Financial Center",
        "customerPhone": "+1 (555) 234-5678",
        "address": "742 Evergreen Terrace, Suite 300, Springfield, IL",
        "latitude": 39.7817,
        "longitude": -89.6501,
        "priority": "HIGH",
        "status": "IN_PROGRESS",
        "scheduledAt": "2026-09-18T10:00:00.000Z",
        "version": 2
      }
    ],
    "page": 1,
    "limit": 20,
    "total": 22,
    "hasNext": true
  },
  "message": "Tasks retrieved successfully"
}
```

### `PATCH /tasks/:id/status`
Updates task status with optimistic locking version verification.

**Request:**
```json
{
  "status": "IN_PROGRESS",
  "version": 1,
  "latitude": 39.7817,
  "longitude": -89.6501
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "id": "task-uuid",
    "status": "IN_PROGRESS",
    "version": 2
  },
  "message": "Task status updated successfully"
}
```

**Conflict Response (409 Conflict):**
```json
{
  "success": false,
  "error": {
    "code": "CONFLICT",
    "message": "Task has been updated on the server. Please resolve conflict.",
    "details": {
      "serverTask": { "id": "task-uuid", "status": "ACCEPTED", "version": 2 },
      "expectedVersion": 1,
      "currentVersion": 2
    }
  }
}
```

---

## 3. Batch Sync Endpoint

### `POST /sync`
Processes a batch of offline operations recorded while the device was disconnected.

**Request:**
```json
{
  "operations": [
    {
      "id": "client-op-1",
      "operationType": "UPDATE",
      "entityType": "TASK",
      "entityId": "task-uuid",
      "payload": { "status": "COMPLETED", "version": 2 },
      "clientTimestamp": "2026-09-18T01:30:00.000Z"
    },
    {
      "id": "client-op-2",
      "operationType": "CREATE",
      "entityType": "NOTE",
      "entityId": "temp-note-id",
      "payload": { "taskId": "task-uuid", "content": "Replaced faulty suction valve" }
    }
  ]
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "operationId": "client-op-1",
        "status": "SYNCED",
        "entityType": "TASK",
        "entityId": "task-uuid",
        "data": { "version": 3, "status": "COMPLETED" }
      },
      {
        "operationId": "client-op-2",
        "status": "SYNCED",
        "entityType": "NOTE",
        "entityId": "generated-note-uuid"
      }
    ],
    "processedCount": 2,
    "conflictCount": 0,
    "failedCount": 0
  },
  "message": "Sync operations processed successfully"
}
```

---

## 4. Health Check

### `GET /health`
Returns service uptime and availability status.

**Response (200 OK):**
```json
{
  "success": true,
  "data": {
    "status": "UP",
    "service": "FIELDFlow Backend API",
    "timestamp": "2026-09-18T02:00:00.000Z",
    "uptime": 128.45,
    "version": "1.0.0"
  },
  "message": "Service is healthy"
}
```

