# FIELDFlow — Complete Project & Architecture Guide
**Offline-First Field Service Management Platform**

---

## Table of Contents
1. [Project Overview & Philosophy](#1-project-overview--philosophy)
2. [Quick-Start Guide (How to Run Everything)](#2-quick-start-guide-how-to-run-everything)
   - [Prerequisites](#prerequisites)
   - [Backend & Database Setup](#backend--database-setup)
   - [Flutter App Launch (Web, Android, Desktop)](#flutter-app-launch-web-android-desktop)
   - [Demo Credentials](#demo-credentials)
3. [Flutter Client Engineering & Architecture](#3-flutter-client-engineering--architecture)
   - [Clean Architecture Layering](#clean-architecture-layering)
   - [State Management (BLoC Pattern)](#state-management-bloc-pattern)
   - [Cross-Platform Database Engine (Drift SQLite + WASM)](#cross-platform-database-engine-drift-sqlite--wasm)
   - [Dependency Injection & Routing](#dependency-injection--routing)
   - [Resilient Networking & Token Interception](#resilient-networking--token-interception)
4. [UI Screens & User Experience](#4-ui-screens--user-experience)
   - [Screen-by-Screen Breakdown](#screen-by-screen-breakdown)
   - [Design System & Theming](#design-system--theming)
5. [Offline-First Architecture & Sync Engine](#5-offline-first-architecture--sync-engine)
   - [Mutation Queue Workflow](#mutation-queue-workflow)
   - [Exponential Backoff Algorithm](#exponential-backoff-algorithm)
   - [Optimistic Concurrency & Conflict Resolution (HTTP 409)](#optimistic-concurrency--conflict-resolution-http-409)
6. [Backend Engineering & Architecture](#6-backend-engineering--architecture)
   - [Technology Stack](#technology-stack)
   - [Database Schema (Prisma ORM)](#database-schema-prisma-orm)
   - [Controller-Service-Repository Pattern](#controller-service-repository-pattern)
   - [Security & Authentication Flow](#security--authentication-flow)
7. [REST API Specification](#7-rest-api-specification)
   - [Endpoints & Use Cases](#endpoints--use-cases)
   - [Batch Sync Payload Example](#batch-sync-payload-example)
8. [Testing & Quality Assurance](#8-testing--quality-assurance)
   - [Flutter Client Test Suite](#flutter-client-test-suite)
   - [Backend Unit Tests](#backend-unit-tests)
   - [CI/CD Automation](#cicd-automation)

---

## 1. Project Overview & Philosophy

**FIELDFlow** is an enterprise-grade, offline-first field service management platform designed for technicians, maintenance engineers, and dispatchers operating in environments with intermittent, poor, or nonexistent network connectivity (tunnels, industrial basements, remote substations, offshore facilities).

### Core Pillars
- **Zero UI Blocking**: The UI strictly reads from and writes to a local SQLite database. User actions never freeze waiting for an HTTP round-trip.
- **Resilient Background Sync**: Mutations are enqueued locally and pushed sequentially or in batches when connectivity is available, backed by exponential backoff retry logic.
- **Optimistic Concurrency Control**: Protects against stale overwrites using version columns. When a conflict occurs (HTTP 409), the user is presented with a side-by-side reconciliation dialog.
- **100% Free & Local-First**: No paid API keys required. OpenStreetMap (`flutter_map`) handles mapping, and a local **Ollama** instance (with a built-in offline expert fallback) handles field diagnostics.

---

## 2. Quick-Start Guide (How to Run Everything)

### Prerequisites
- **Node.js**: v18+ (tested on Node v22)
- **Flutter SDK**: 3.27+ (tested on Flutter 3.47.4 / Dart 3.13.3)
- **PostgreSQL**: Native Windows PostgreSQL (port 5432) or Docker Desktop
- **Google Chrome** (for Web) or **Android Device/Emulator** (for Mobile)

---

### Backend & Database Setup

1. **Navigate to the backend folder**:
   ```powershell
   cd backend
   ```

2. **Verify Environment Variables** (`backend/.env`):
   ```env
   PORT=5000
   NODE_ENV=development
   DATABASE_URL="postgresql://postgres:password@localhost:5432/fieldflow?schema=public"
   JWT_ACCESS_SECRET="fieldflow_access_token_super_secret_jwt_key_2026"
   JWT_REFRESH_SECRET="fieldflow_refresh_token_super_secret_jwt_key_2026"
   JWT_ACCESS_EXPIRATION="15m"
   JWT_REFRESH_EXPIRATION="7d"
   CORS_ORIGIN="*"
   UPLOAD_DIR="./uploads"
   ```

3. **Push Prisma Schema to PostgreSQL**:
   ```powershell
   npx prisma db push
   ```

4. **Seed Database with 22 Industrial Tasks**:
   ```powershell
   npm run prisma:seed
   ```

5. **Start Development Server**:
   ```powershell
   npm run dev
   ```
   *The server will start listening at `http://0.0.0.0:5000`.*
   *Healthcheck: `http://localhost:5000/api/v1/health`.*

---

### Flutter App Launch (Web, Android, Desktop)

#### Target A: Google Chrome (Fastest & Zero Setup)
```powershell
cd mobile
flutter run -d chrome
```
*The app compiles with WebAssembly SQLite (`sql.js`) and runs in the browser.*

#### Target B: Android Emulator
```powershell
# 1. Launch the Android Emulator
flutter emulators --launch Pixel_10a

# 2. Run the application
cd mobile
flutter run
```

#### Target C: Physical Android Phone (over USB)
1. Connect your phone via USB with **USB Debugging** enabled in Developer Options.
2. Enable port forwarding so the device can reach the host machine:
   ```powershell
   adb reverse tcp:5000 tcp:5000
   adb reverse tcp:11434 tcp:11434
   ```
3. Run the app:
   ```powershell
   cd mobile
   flutter run
   ```

#### Target D: Windows Desktop
1. Enable Windows Developer Mode (`start ms-settings:developers`).
2. Run:
   ```powershell
   cd mobile
   flutter run -d windows
   ```

---

### Demo Credentials

The login screen features **Quick-Fill Buttons** for rapid testing:

| Role | Email | Password | Pre-Assigned Tasks |
| :--- | :--- | :--- | :--- |
| **Field Worker 1** | `worker@example.com` | `password123` | **17 Tasks** (HVAC, Solar, Optical, Chillers) |
| **Field Worker 2** | `worker2@example.com` | `password123` | **5 Tasks** (Electrical, Generators) |
| **Administrator** | `admin@fieldflow.dev` | `admin123` | Full access across all work orders |

---

## 3. Flutter Client Engineering & Architecture

### Clean Architecture Layering

The `mobile/lib` project adheres strictly to **Clean Architecture** principles:

```text
mobile/lib/
├── core/                       # Shared platform utilities & cross-cutting concerns
│   ├── constants/              # AppColors, ApiConstants, StorageKeys
│   ├── database/               # Drift SQLite database, DAO, Tables, Connection abstraction
│   │   └── connection/         # Conditional imports (native.dart, web.dart, connection.dart)
│   ├── errors/                 # Failure and Exception hierarchy
│   ├── network/                # ApiClient (Dio), AuthInterceptor, NetworkInfo
│   ├── routing/                # GoRouter configuration & route guards
│   ├── storage/                # FlutterSecureStorage wrapper
│   ├── theme/                  # Material 3 dark & light theme definitions
│   └── widgets/                # StatusBadge, PriorityChip, SkeletonLoader, EmptyStateView
│
└── features/                   # Independent vertical feature modules
    ├── auth/                   # Authentication & profile management
    ├── dashboard/              # Metrics, KPI ring, sync pill, priority tasks
    ├── tasks/                  # Work orders, filtering, transitions, conflict modal
    ├── sync/                   # SyncManager, exponential backoff, sync center UI
    ├── location/               # GPS tracking, OpenStreetMap task viewer
    ├── ai_assistant/           # Ollama generative assistant + offline expert engine
    └── notifications/          # Local push notifications & alert drawer
```

Each feature is organized into three strictly isolated layers:
1. **Domain Layer**: Pure Dart business logic.
   - `entities/`: Immutable models (`Task`, `TaskStatus`, `Priority`, `User`).
   - `repositories/`: Abstract repository contracts.
   - `usecases/`: Single-responsibility use cases (`GetTasksUseCase`, `UpdateTaskStatusUseCase`).
2. **Data Layer**: Infrastructure and persistence.
   - `models/`: JSON/Drift data-transfer objects with serializable mappers.
   - `datasources/`: Local (Drift SQLite) and Remote (Dio REST client) data sources.
   - `repositories/`: Implementations of domain repository interfaces coordinating local cache and remote API.
3. **Presentation Layer**: Reactive user interface.
   - `bloc/`: BLoC classes, Events, and States.
   - `pages/`: Full-page widget screens.
   - `widgets/`: Reusable UI components.

---

### State Management (BLoC Pattern)

We use `flutter_bloc` to achieve predictable, unidirectional state flows:

```mermaid
flowchart LR
    UI[Widget Tree] -->|Dispatches Event| Bloc[BLoC / Cubit]
    Bloc -->|Invokes| UseCase[Domain Use Case]
    UseCase -->|Requests Data| Repo[Repository]
    Repo -->|Watches Local DB| SQLite[(Drift SQLite Cache)]
    SQLite -->|Emits Stream| Repo
    Repo -->|Stream Updates| Bloc
    Bloc -->|Emits New State| UI
```

- **`TaskBloc`**: Subscribes directly to Drift SQLite stream watchers via `GetTasksUseCase.watch()`. Whenever SQLite updates (either from local user action or background sync), the UI updates **instantly** without polling.
- **`SyncBloc`**: Emits the current state of pending synchronization operations, active sync status, and network connection health.
- **`AuthBloc`**: Manages session state (`Authenticated`, `Unauthenticated`, `AuthLoading`, `AuthFailureState`).
- **`AiAssistantBloc`**: Manages queries to the local Ollama LLM or falls back seamlessly to the Rule-Based Expert Engine.

---

### Cross-Platform Database Engine (Drift SQLite + WASM)

To guarantee that the app compiles and runs identically across **Android, iOS, Windows, macOS, Linux, and Chrome (Web)**, we implemented a **conditional connection abstraction**:

```text
lib/core/database/connection/
├── connection.dart     # Selects engine using conditional exports
├── native.dart         # NativeDatabase + dart:ffi + sqlite3_flutter_libs (Android/Desktop)
├── web.dart            # WebDatabase + IndexedDB + sql-wasm.js (Chrome/Web)
└── unsupported.dart    # Fallback stub for unsupported platforms
```

- On **Native devices**, Drift communicates directly with the high-performance C SQLite engine via `dart:ffi`.
- On **Web browsers**, Drift boots a WebAssembly SQLite virtual machine (`sql.js`) and persists all tables to the browser's IndexedDB.

---

### Dependency Injection & Routing

- **Dependency Injection (`get_it`)**: All databases, services, repositories, use cases, and BLoCs are registered in `lib/injection/dependency_injection.dart`.
- **Declarative Routing (`go_router`)**: Managed in `lib/core/routing/app_router.dart` with dedicated routes:
  - `/login`: User authentication screen
  - `/`: Main navigation shell with bottom bar (Dashboard, Tasks, Map, Sync, AI)
  - `/tasks/:id`: Deep work-order details
  - `/sync`: Real-time synchronization monitor
  - `/notifications`: Background alerts view

---

### Resilient Networking & Token Interception

`ApiClient` encapsulates `Dio` with a production **`AuthInterceptor`**:
1. **Automatic Token Attachment**: Automatically injects `Authorization: Bearer <token>` from encrypted storage.
2. **Automatic 401 Refresh**: Intercepts `401 Unauthorized` responses, halts the request queue, calls `/auth/refresh` using the stored refresh token, updates secure storage, and replays failed requests transparently.
3. **Session Invalidation**: If the refresh token is expired or revoked, securely clears the tokens and redirects the user to `/login`.

---

## 4. UI Screens & User Experience

### Screen-by-Screen Breakdown

```
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│   Login Screen  │──>│ Dashboard Screen│──>│ Task List Screen│
└─────────────────┘   └─────────────────┘   └─────────────────┘
                               │                     │
                               ▼                     ▼
                      ┌─────────────────┐   ┌─────────────────┐
                      │  AI Diagnostics │   │ Task Details UI │
                      └─────────────────┘   └─────────────────┘
                               │                     │
                               ▼                     ▼
                      ┌─────────────────┐   ┌─────────────────┐
                      │   Sync Center   │   │  OpenStreetMap  │
                      └─────────────────┘   └─────────────────┘
```

#### 1. Login Screen (`login_page.dart`)
- Industrial field branding with high-contrast inputs.
- Client-side email and password validation.
- Quick-Fill Demo Cards to sign in with one tap.
- Graceful error banner for invalid credentials.

#### 2. Dashboard Screen (`dashboard_page.dart`)
- Personalized worker greeting with real-time shift status.
- **KPI Metrics Cards**: Total Assigned, In Progress, Critical Priority, Completed.
- **Circular Progress Ring**: Interactive visual completion rate percentage.
- **Sync Status Pill**: Visual indicator showing "All Synced" (green) or "X Pending" (amber).
- **High-Priority Task Cards**: Direct shortcuts to overdue or critical jobs.

#### 3. Task List Screen (`task_list_page.dart`)
- Live search bar with debouncing (filters by job title, customer, or address).
- Filter bottom-sheet: Multi-select status (`ASSIGNED`, `ACCEPTED`, `IN_PROGRESS`, `COMPLETED`) and priority (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`).
- Shimmer skeleton loaders during initial synchronization.
- Status badges and priority chips with high-contrast color coding.

#### 4. Task Details Screen (`task_details_page.dart`)
- Customer details with one-touch phone dialer (`tel:`) and GPS map navigation (`geo:`).
- Work order description, scheduled date/time, and equipment identifiers.
- **Validated Status Transition Workflow**:
  - `ASSIGNED` → `ACCEPTED`
  - `ACCEPTED` → `IN_PROGRESS`
  - `IN_PROGRESS` → `COMPLETED`
  - Direct cancellation option from any active state.
- **Field Notes Modal**: Add GPS-tagged, timestamped text notes.
- **Field Camera Trigger**: Capture or attach photos to the job.
- **Conflict Resolution Modal**: Triggered on concurrency collisions.

#### 5. OpenStreetMap Route Viewer (`task_map_page.dart`)
- Fully interactive map rendered via `flutter_map` (OpenStreetMap).
- Displays customer site location pin and technician GPS location pin.
- Dynamic distance calculation between technician and target site.
- One-click button to launch external turn-by-turn navigation (Google Maps / Apple Maps).

#### 6. Sync Center Screen (`sync_center_page.dart`)
- Live inspection of queued synchronization operations (`SyncQueue` table).
- Shows operation type (`UPDATE_STATUS`, `ADD_NOTE`, `UPLOAD_PHOTO`), retry attempts, and timestamps.
- Manual **"Sync Now"** trigger button.
- Network status bar indicating real-time online/offline connectivity.

#### 7. AI Diagnostic Assistant Screen (`ai_assistant_page.dart`)
- Interactive diagnostic chat assistant powered by local **Ollama** (`llama3.2` or `mistral`).
- Quick-select equipment presets: *Commercial HVAC*, *Chiller Plant*, *Solar Inverter*, *Emergency Generator*, *Fiber Optics*.
- **Automatic Offline Fallback**: If Ollama is not running, the built-in **Rule-Based Field Expert Engine** provides instant, step-by-step diagnostic checklists and safety protocols without requiring any internet access or paid API keys.

#### 8. Notifications Screen (`notifications_page.dart`)
- Chronological list of dispatch alerts and task assignments.
- Unread indicator badges with swipe-to-read or mark-all-as-read options.

#### 9. Profile Screen (`profile_page.dart`)
- Worker profile information, role identifier (`FIELD_WORKER` / `ADMIN`), and device cache metrics.
- One-click secure workstation sign-out.

---

## 5. Offline-First Architecture & Sync Engine

### Mutation Queue Workflow

FIELDFlow employs a **Local-First / Offline-First mutation queue** architecture:

```mermaid
sequenceDiagram
    autonumber
    actor Tech as Field Technician
    participant UI as Flutter UI
    participant DB as Local Drift SQLite
    participant Sync as SyncManager
    participant API as Backend REST API
    participant PG as PostgreSQL Database

    Tech->>UI: Updates Task Status to IN_PROGRESS
    UI->>DB: 1. Update TasksTable (status = IN_PROGRESS)
    UI->>DB: 2. Insert into SyncQueue (action = UPDATE_STATUS, status = PENDING)
    DB-->>UI: Reactive Stream emits updated task
    UI-->>Tech: Instant UI confirmation (Zero latency)

    Note over Sync,API: SyncManager checks connectivity
    alt Device is Online
        Sync->>DB: Query PENDING operations (ordered by created_at)
        Sync->>API: POST /api/v1/sync (Batch payload)
        API->>PG: Validate versions & apply mutations
        PG-->>API: Success (New versions)
        API-->>Sync: 200 OK (Processed operations)
        Sync->>DB: Mark operations COMPLETED (or delete)
        Sync->>DB: Upsert new server task versions
    else Device is Offline
        Sync-->>Sync: Backoff timer waits for connectivity_plus event
    end
```

---

### Exponential Backoff Algorithm

If the remote backend is unreachable, the sync engine applies an exponential backoff formula:

$$\text{Delay} = \min\left(2^{\text{retryCount}}, 16\right) \text{ seconds}$$

| Attempt | Backoff Calculation | Wait Time Before Retry |
| :---: | :---: | :---: |
| 1 | $2^1$ | **2 seconds** |
| 2 | $2^2$ | **4 seconds** |
| 3 | $2^3$ | **8 seconds** |
| 4 | $2^4$ | **16 seconds** |
| 5 | $\min(2^5, 16)$ | **16 seconds (capped)** |
| > 5 | — | Marked as `FAILED` (Inspected in Sync Center) |

---

### Optimistic Concurrency & Conflict Resolution (HTTP 409)

To prevent multiple technicians or dispatchers from overwriting each other's changes, every task record has an integer `version` column:

1. When updating a task, the client sends its current `currentVersion`.
2. The server compares `currentVersion` with the database `task.version`.
3. If `currentVersion !== task.version`, the server rejects the update with **HTTP 409 Conflict**:
   ```json
   {
     "success": false,
     "error": {
       "code": "CONFLICT",
       "message": "Task was modified by another user",
       "details": {
         "serverTask": { "id": "...", "status": "COMPLETED", "version": 3 },
         "clientVersion": 1,
         "serverVersion": 3
       }
     }
   }
   ```
4. The Flutter client receives HTTP 409, marks the sync operation as `CONFLICT`, and presents the **Side-by-Side Conflict Resolution Dialog**:
   - **Keep Local**: Overwrites server data with the client's version.
   - **Accept Server**: Discards local changes and updates SQLite cache with server state.
   - **Merge**: Keeps local notes while adopting server status.

---

## 6. Backend Engineering & Architecture

### Technology Stack
- **Runtime**: Node.js v22 with TypeScript v5.9
- **Framework**: Express.js
- **ORM**: Prisma ORM v5.22
- **Database**: PostgreSQL 16+
- **Authentication**: JWT (`jsonwebtoken`) with `bcrypt` password hashing
- **Validation**: Zod schema validation middleware
- **Logging**: Custom structured logger masking sensitive attributes

---

### Database Schema (Prisma ORM)

```mermaid
erDiagram
    User ||--o{ Task : "assignedTasks"
    User ||--o{ TaskNote : "author"
    User ||--o{ Notification : "recipient"
    Task ||--o{ TaskNote : "notes"
    Task ||--o{ TaskPhoto : "photos"
    Task ||--o{ Location : "locations"

    User {
        string id PK
        string email UK
        string passwordHash
        string name
        enum role "ADMIN | FIELD_WORKER"
        datetime createdAt
        datetime updatedAt
    }

    Task {
        string id PK
        string title
        string description
        string customerName
        string customerPhone
        string address
        float latitude
        float longitude
        enum priority "LOW | MEDIUM | HIGH | CRITICAL"
        enum status "ASSIGNED | ACCEPTED | IN_PROGRESS | COMPLETED | CANCELLED"
        datetime scheduledAt
        int version
        string assignedToId FK
        datetime createdAt
        datetime updatedAt
    }

    TaskNote {
        string id PK
        string taskId FK
        string authorId FK
        string content
        float latitude
        float longitude
        datetime createdAt
    }

    TaskPhoto {
        string id PK
        string taskId FK
        string fileUrl
        string caption
        float latitude
        float longitude
        datetime createdAt
    }

    Location {
        string id PK
        string taskId FK
        float latitude
        float longitude
        datetime recordedAt
    }

    Notification {
        string id PK
        string userId FK
        string title
        string message
        boolean isRead
        datetime createdAt
    }
```

---

### Security & Authentication Flow
- **Password Security**: Passwords are salted and hashed using `bcrypt` (10 rounds).
- **Short-Lived Access Tokens**: Signed with `JWT_ACCESS_SECRET`, expire in 15 minutes.
- **Long-Lived Refresh Tokens**: Signed with `JWT_REFRESH_SECRET`, expire in 7 days.
- **Strict Role-Based Access Control (RBAC)**: `auth.middleware.ts` enforces role permissions (`Role.ADMIN` vs `Role.FIELD_WORKER`).

---

## 7. REST API Specification

### Endpoints & Use Cases

| Method | Route | Auth | Description |
| :--- | :--- | :---: | :--- |
| `POST` | `/api/v1/auth/login` | Public | Authenticates credentials and returns JWT pair |
| `POST` | `/api/v1/auth/refresh` | Public | Exchanges valid refresh token for a new access token |
| `GET` | `/api/v1/auth/me` | Bearer | Fetches currently authenticated user profile |
| `POST` | `/api/v1/auth/logout` | Bearer | Invalidates active user session |
| `GET` | `/api/v1/tasks` | Bearer | Returns paginated, filtered tasks (`page`, `limit`, `status`, `priority`, `search`) |
| `GET` | `/api/v1/tasks/:id` | Bearer | Fetches comprehensive task detail including notes, photos, and breadcrumbs |
| `PATCH`| `/api/v1/tasks/:id/status` | Bearer | Updates task status with version check (`version`, `status`) |
| `POST` | `/api/v1/tasks/:id/notes` | Bearer | Adds a timestamped, GPS-tagged technician note |
| `POST` | `/api/v1/tasks/:id/photos`| Bearer | Uploads a photo attachment with geolocation metadata |
| `POST` | `/api/v1/tasks/:id/locations`| Bearer| Appends technician breadcrumb coordinates |
| `POST` | `/api/v1/sync` | Bearer | Atomic batch synchronization endpoint for offline queue |
| `GET` | `/api/v1/notifications` | Bearer | Retrieves user notifications |
| `PATCH`| `/api/v1/notifications/:id/read` | Bearer | Marks a notification as read |
| `GET` | `/api/v1/health` | Public | Healthcheck reporting uptime, database status, and version |

---

### Batch Sync Payload Example (`POST /api/v1/sync`)

```json
{
  "operations": [
    {
      "id": "c7a8b3f1-4321-4f11-89ab-123456789abc",
      "type": "UPDATE_STATUS",
      "taskId": "2557af38-3fde-4237-97b1-303dbf894ab3",
      "payload": {
        "status": "IN_PROGRESS",
        "version": 1
      },
      "createdAt": "2026-09-20T01:15:00.000Z"
    },
    {
      "id": "e9f0d1a2-5678-4a22-90cd-987654321def",
      "type": "ADD_NOTE",
      "taskId": "2557af38-3fde-4237-97b1-303dbf894ab3",
      "payload": {
        "content": "Flue gas analyzer calibrated; combustion efficiency at 84%.",
        "latitude": 44.9778,
        "longitude": -93.265
      },
      "createdAt": "2026-09-20T01:17:30.000Z"
    }
  ]
}
```

---

## 8. Testing & Quality Assurance

### Flutter Client Test Suite
Run from `mobile/`:
```powershell
flutter test
```
**Results: 20 / 20 Tests Passed**

1. **Task Status Transition Unit Tests** (`test/unit/tasks/task_status_transition_test.dart`):
   - Verifies `ASSIGNED` can only transition to `ACCEPTED` or `CANCELLED`.
   - Verifies `ACCEPTED` can only transition to `IN_PROGRESS` or `CANCELLED`.
   - Verifies `IN_PROGRESS` can only transition to `COMPLETED` or `CANCELLED`.
   - Verifies `COMPLETED` and `CANCELLED` are terminal states.
2. **Sync Backoff Unit Tests** (`test/unit/sync/sync_manager_test.dart`):
   - Verifies mathematical exponential scaling ($2^1, 2^2, 2^3$).
   - Verifies ceiling cap at 16 seconds.
3. **Auth BLoC Unit Tests** (`test/unit/auth/auth_bloc_test.dart`):
   - Tests `CheckAuthStatus`, `LoginSubmitted`, and `LogoutRequested` transitions.
4. **Widget Tests**:
   - `test/widget/task_card_test.dart`: Verifies card rendering, status chip, and tap interaction.
   - `test/widget/sync_status_widget_test.dart`: Verifies sync indicator animations.
   - `test/widget/conflict_dialog_test.dart`: Verifies side-by-side reconciliation buttons and callbacks.
5. **End-to-End Offline Sync Flow** (`test/integration/offline_sync_flow_test.dart`):
   - Simulates updating a task while completely offline.
   - Verifies immediate SQLite persistence and pending queue insertion.
   - Simulates network restoration and validates remote batch synchronization.

---

### Backend Unit Tests
Run from `backend/`:
```powershell
npm test
```
**Results: 12 / 12 Tests Passed**
- JWT generation and verification unit tests.
- Status transition state-machine validation tests.

---

### CI/CD Automation (`.github/workflows/ci.yml`)

The repository includes a complete GitHub Actions pipeline executing on every push and pull request:
1. **Flutter Job**:
   - Formats check (`dart format --output=none --set-exit-if-changed .`)
   - Static analysis (`flutter analyze --no-fatal-infos`)
   - Complete unit and widget tests (`flutter test`)
2. **Backend Job**:
   - Linter check
   - TypeScript compilation (`npm run build`)
   - Jest unit tests (`npm test`)

---

## Summary of Completed Files

```text
field_flow/
├── docker-compose.yml              # PostgreSQL + Backend production containers
├── README.md                       # High-level overview & screenshots
├── PROJECT_GUIDE.md                # (This Document) Complete Technical & Usage Manual
├── .github/workflows/ci.yml        # Multi-stage CI/CD pipeline
│
├── backend/                        # Node.js + TypeScript + Express + Prisma
│   ├── prisma/schema.prisma        # PostgreSQL data schema
│   ├── prisma/seed.ts              # 22 realistic industrial field tasks
│   ├── src/controllers/            # REST endpoint controllers
│   ├── src/services/               # Business logic & RBAC
│   ├── src/routes/                 # Express route definitions
│   └── tests/                      # Jest unit tests
│
└── mobile/                         # Flutter 3.27+ Clean Architecture
    ├── lib/core/                   # Shared database, network, theme, routing
    ├── lib/features/auth/          # Authentication & Profile
    ├── lib/features/dashboard/     # KPI ring, status overview
    ├── lib/features/tasks/         # Work orders, transitions, conflicts
    ├── lib/features/sync/          # SyncManager & exponential backoff
    ├── lib/features/location/      # GPS tracking & OpenStreetMap
    ├── lib/features/ai_assistant/  # Ollama & Offline Expert Fallback
    ├── test/                       # 20 unit, widget, and integration tests
    └── web/                        # Web runner with bundled SQLite WASM
```
