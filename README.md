# 🌾 Agrosul-Tech — Autonomous Precision Agriculture Platform

> **AI Swarm + Spatial Database + Real-Time Advisory for Brazilian Agribusiness**  
> Stack: Python · PostgreSQL/PostGIS · Next.js · YOLOv8 · Pub/Sub Event Bus

[![Backend](https://img.shields.io/badge/Backend-Python%203.10+-3776AB?logo=python&logoColor=white)](./backend)
[![Portal](https://img.shields.io/badge/Portal-Next.js%2015-000000?logo=next.js&logoColor=white)](./portal)
[![Database](https://img.shields.io/badge/Database-PostgreSQL%2015%20+%20PostGIS-4169E1?logo=postgresql&logoColor=white)](./backend/scripts/init_db.sql)
[![AI](https://img.shields.io/badge/AI-YOLOv8%20+%20Pydantic%20Swarm-FF6B35)](./backend/swarm)

---

## 📌 Executive Summary

Agrosul-Tech is a **multi-tenant, AI-driven precision agriculture SaaS platform** designed for large-scale Brazilian producers (500–50,000 ha). It replaces fragmented agronomy workflows with a unified intelligent system that:

1. **Ingests** real-world data (weather, commodity prices, satellite NDVI, drone telemetry)
2. **Analyzes** it through a swarm of specialized AI agents in real-time
3. **Generates** autonomous prescriptions (spot-spraying maps, VRT nitrogen maps, harvest routing, replanting plans)
4. **Delivers** alerts and directives to a web-based Pilot Dashboard (Next.js portal)

The platform is built around **three pillars**:

| Pillar | What it does | Technology |
|--------|-------------|------------|
| **Oracle** | Fetches external data feeds (weather, market, news) on a schedule | Python `schedule` loop + 3 specialized workers |
| **Swarm** | 5 AI agents analyze Oracle data via a Pub/Sub event bus | Python + Pydantic event model |
| **Portal** | Next.js dashboard for pilots/agronomists — receives real-time alerts | Next.js 15 + Webhook API |

---

## 🏗️ Monorepo Architecture

```
agrosul/                              ← This repository
│
├── README.md                         ← You are here
├── .gitignore
│
├── backend/                          ← Python backend (Oracle + Swarm)
│   ├── .gitignore
│   │
│   ├── oracle/                       ← The Global Data Oracle (Phase 2.5)
│   │   ├── main.py                   ← Oracle entry point — runs the scheduler loop
│   │   ├── db_client.py              ← PostgreSQL/PostGIS connection client
│   │   ├── requirements.txt          ← Oracle Python dependencies
│   │   └── workers/
│   │       ├── weather_worker.py     ← Fetches weather data (OpenWeatherMap / INMET)
│   │       ├── market_worker.py      ← Fetches commodity prices (B3, CBOT)
│   │       └── news_worker.py        ← Scrapes agronomic news + NLP sentiment
│   │
│   ├── swarm/                        ← The AI Agent Swarm (Phase 3–4)
│   │   ├── coordinator.py            ← SwarmCoordinator: Pub/Sub event bus (singleton)
│   │   ├── webhook_client.py         ← Dispatches portal events to Next.js via HTTP POST
│   │   ├── requirements.txt          ← Swarm Python dependencies
│   │   └── agents/
│   │       ├── aero.py               ← 🛸 AERO — Flight Safety & Compliance
│   │       ├── ceres.py              ← 🌾 CERES — Computer Vision Core (YOLOv8)
│   │       ├── fauna.py              ← 🐛 FAUNA — Biological Cycle Prediction
│   │       ├── solis.py              ← 🛰️ SOLIS — Satellite Macro NDVI Monitoring
│   │       └── mercurius_plutus.py   ← 💰 MERCURIUS — Financial ROI & Logistics
│   │
│   └── scripts/
│       ├── init_db.sql               ← Full PostgreSQL/PostGIS database schema
│       └── import_dem.ps1            ← PowerShell: imports Digital Elevation Model rasters
│
└── portal/                           ← Next.js 15 Pilot Dashboard
    ├── package.json
    ├── next.config.ts
    ├── tsconfig.json
    ├── public/
    └── src/
        ├── app/
        │   ├── layout.tsx
        │   ├── page.tsx              ← Main dashboard entry point
        │   ├── globals.css           ← Global styles + design system
        │   └── api/
        │       └── notifications/    ← POST endpoint: receives Swarm webhooks
        ├── components/
        │   ├── AuthScreen.tsx        ← Authentication UI
        │   ├── PilotDashboard.tsx    ← Drone pilot mission interface
        │   ├── ProducerDashboard.tsx ← Farm owner analytics & alerts
        │   └── FieldToCloudIngestion.tsx ← Orthomosaic upload pipeline
        ├── lib/                      ← Shared utilities
        ├── types/                    ← TypeScript type definitions
        ├── i18n/                     ← Internationalization (PT-BR / EN)
        └── locales/                  ← Translation strings
```

---

## 🤖 The AI Agent Swarm — Roles & Responsibilities

Each agent is a **specialized, autonomous Python class** that subscribes to topics on the Swarm Event Bus and reacts to data in real time. Agents are loosely coupled — they only communicate through the coordinator, never directly.

### 🛸 AERO — Flight Safety & Compliance Agent
**File:** [`backend/swarm/agents/aero.py`](./backend/swarm/agents/aero.py)

| Trigger | Action |
|---------|--------|
| `oracle.weather.alert` | Evaluates wind speed (>10 m/s) and precipitation (>20mm). Issues RTL (Return-To-Launch) advisory to all active pilots via portal. |
| `telemetry.mission_started` | Queries `socio_legal_boundaries` table (PostGIS) to verify the flight path doesn't cross indigenous lands, ANAC restricted airspace, or protected environmental areas. |

---

### 🌾 CERES — Computer Vision Core
**File:** [`backend/swarm/agents/ceres.py`](./backend/swarm/agents/ceres.py)

Runs **YOLOv8 deep learning** on high-resolution orthomosaics. Supports 6 agronomic analysis modes:

| Mission Type | What CERES Does | Output |
|-------------|----------------|--------|
| `PRE_PLANT_TOPO` | Calculates DEM + hydrological flow | GeoTIFF / SHP |
| `STAND_COUNT_EMERGENCE` | Sub-centimeter plant counting, germination gap detection | SHP replanting map |
| `CROP_HEALTH_NDVI` | Calibrates RedEdge/NIR multispectral bands, generates VRT nutrition map | ISO-XML for spreader tractor |
| `PEST_DAMAGE_ASSESSMENT` | Classifies foliar damage severity (Spodoptera/Broca) | SHP emergency pesticide zones |
| `HARVEST_ROUTING` | Hough Transform on planting lines, generates A-B guidance lines | ISO-XML for tractor auto-steer |
| `WEED_SCOUTING` | YOLO object detection for weed clusters → spot-spraying prescription | SHP spot-spray map |

---

### 🐛 FAUNA — Biological Cycle Prediction Agent
**File:** [`backend/swarm/agents/fauna.py`](./backend/swarm/agents/fauna.py)

| Trigger | Action |
|---------|--------|
| `oracle.weather.log` | Accumulates **Degree Days** from daily temperature (base 10°C). When threshold >450 ADD is reached, predicts Spittlebug (*Mahanarva fimbriolata*) nymph hatching with 89% confidence and dispatches a scouting mission alert. |

> **Why this matters:** Spittlebug is the #1 pest threat to Brazilian sugarcane, causing up to 30% yield loss. Predictive detection 3–5 days before hatching is a major economic advantage.

---

### 🛰️ SOLIS — Satellite Macro Monitoring Agent
**File:** [`backend/swarm/agents/solis.py`](./backend/swarm/agents/solis.py)

| Trigger | Action |
|---------|--------|
| `oracle.satellite.ndvi_update` | Analyzes wide-scale spectral indices (Sentinel-2 / Landsat). If NDVI drops >15% vs. baseline, creates a priority scouting mission directive pinpointing the exact anomaly polygon. |

---

### 💰 MERCURIUS — Financial ROI & Logistics Agent
**File:** [`backend/swarm/agents/mercurius_plutus.py`](./backend/swarm/agents/mercurius_plutus.py)

| Trigger | Action |
|---------|--------|
| `oracle.market.price_update` | Updates real-time commodity price ledger (sugarcane, soybean, corn in BRL/ton). |
| `solis.directive.dispatch_ceres` | Calculates **Intervention ROI** — weighs flight cost (R$450) against projected yield saved. Only approves dispatch if ROI is positive. This is the platform's **financial circuit breaker**. |

---

## 🔄 System Flow

```
┌─────────────────────────────────────────────────────────┐
│                    THE ORACLE                           │
│  weather_worker ──┐                                     │
│  market_worker  ──┼──► PostgreSQL/PostGIS               │
│  news_worker    ──┘    (oracle_weather_logs,            │
│                         oracle_market_prices,           │
│                         oracle_agronomic_news)          │
└──────────────────────────┬──────────────────────────────┘
                           │ Publishes SwarmEvents
                           ▼
┌─────────────────────────────────────────────────────────┐
│               SWARM COORDINATOR (Event Bus)             │
│  Topic: oracle.weather.alert  ──────────► AERO          │
│  Topic: oracle.market.price_update ─────► MERCURIUS     │
│  Topic: oracle.satellite.ndvi_update ───► SOLIS         │
│  Topic: oracle.weather.log ─────────────► FAUNA         │
│  Topic: ingestion.orthomosaic.completed ► CERES         │
└──────────────────────────┬──────────────────────────────┘
                           │ Agents publish portal.* events
                           ▼
┌─────────────────────────────────────────────────────────┐
│                   WEBHOOK CLIENT                        │
│  Any event with topic "portal.*" is intercepted and     │
│  dispatched via HTTP POST to:                           │
│  http://localhost:3000/api/notifications                │
└──────────────────────────┬──────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│              NEXT.JS PILOT DASHBOARD (Portal)           │
│  • Real-time mission alerts                             │
│  • Prescription map downloads                           │
│  • Flight authorization confirmations                   │
│  • NDVI anomaly visualizations                          │
│  • Orthomosaic upload → CERES pipeline                  │
└─────────────────────────────────────────────────────────┘
```

---

## 🗄️ Database Architecture (PostgreSQL + PostGIS)

**Schema:** [`backend/scripts/init_db.sql`](./backend/scripts/init_db.sql)

### Core Tables

| Table | Purpose |
|-------|---------|
| `producers` | Top-level tenant (e.g., "Raizen", "Cargill") |
| `farms` | Farms belonging to a producer |
| `farm_plots` | Individual crop plots — PostGIS `Polygon(4326)` with GIST spatial index |
| `digital_elevation_hydrology` | DEM rasters + flow lines + slope data per plot |
| `socio_legal_boundaries` | Indigenous lands, protected areas, ANAC restricted zones |
| `soil_mechanics` | Clay/silt/sand ratios + compaction risk per plot zone |
| `field_notes` | Free-text pilot observations per plot |
| `flight_telemetry` | 3D GPS point stream (`PointZ`) — **partitioned by month** |
| `oracle_weather_logs` | Weather timeseries per plot |
| `oracle_market_prices` | Commodity prices with exchange + contract date |
| `oracle_agronomic_news` | NLP-enriched news (sentiment JSONB, affected commodities) |
| `portal_notifications` | Swarm → Portal alerts with agent source, priority, read status |

### Enterprise Row-Level Security

```sql
-- App backend sets this on every request:
SET LOCAL app.tenant_id = 'producer-uuid-here';
-- All queries are automatically scoped to that producer only
```

---

## 🛠️ Developer Setup

### Prerequisites

- Python 3.10+
- PostgreSQL 15+ with PostGIS extension
- Node.js 18+
- (Optional) GPU for CERES YOLOv8 inference

### 1. Database

```bash
createdb agrosul_db
psql -d agrosul_db -f backend/scripts/init_db.sql
# Windows — import DEM rasters (optional):
.\backend\scripts\import_dem.ps1
```

### 2. Oracle

```bash
cd backend/oracle
pip install -r requirements.txt

export OPENWEATHER_API_KEY="your_key"
export DB_CONNECTION_STRING="postgresql://user:pass@localhost/agrosul_db"

python main.py
```

**Oracle Schedule:** Weather every 10 min · Market prices every 1 hr · News every 2 hrs

### 3. Swarm

```bash
cd backend/swarm
pip install -r requirements.txt

export NEXTJS_PORTAL_URL="http://localhost:3000/api/notifications"

python -c "import agents.aero; import agents.ceres; import agents.fauna; import agents.solis; import agents.mercurius_plutus; print('Swarm initialized')"
```

### 4. Portal

```bash
cd portal
npm install
npm run dev
# Portal available at http://localhost:3000
```

---

## 🚀 Development Roadmap

| Phase | Status | Description |
|-------|--------|-------------|
| **1 — Spatial Foundation** | ✅ Done | PostgreSQL/PostGIS schema: producers, farms, plots, soil, DEM, legal boundaries |
| **1.5 — Multi-Tenant RLS** | ✅ Done | Row-Level Security for full producer data isolation |
| **2 — Flight Telemetry** | ✅ Done | Partitioned `flight_telemetry` table for high-volume GPS streams |
| **2.5 — Global Data Oracle** | ✅ Done | Oracle workers: weather, market prices, agronomic news |
| **3 — AI Swarm Core** | ✅ Done | Pub/Sub coordinator + 5 agents (Aero, Ceres, Fauna, Solis, Mercurius) |
| **4 — Portal Webhooks** | ✅ Done | Webhook client dispatching swarm events to Next.js portal |
| **5 — Portal UI** | 🔄 In Progress | Next.js dashboard with real-time notifications, map viewer, prescription downloads |
| **6 — Pilot Upload Pipeline** | 🔜 Next | Orthomosaic ingestion pipeline: pilot uploads → S3/GCS → triggers CERES |
| **7 — Satellite Integration** | 🔜 Next | Sentinel-2 / Landsat NDVI feeds into SOLIS automatically |
| **8 — Production Deployment** | 🔜 Future | Docker Compose → Kubernetes, CI/CD, pg_partman for auto-partitioning |

---

## 🔐 Security Architecture

| Layer | Implementation |
|-------|---------------|
| **Data Isolation** | PostgreSQL Row-Level Security — producers cannot see each other's data |
| **API Auth** | JWT bearer tokens on the Next.js portal API |
| **Database** | Parameterized queries only — no string interpolation |
| **Secrets** | Environment variables (never hardcoded) |
| **Telemetry** | Encrypted in transit (TLS) |

---

## 📦 Key Technologies

| Technology | Role |
|-----------|------|
| **Python 3.10+** | Oracle workers, Swarm agents, Coordinator |
| **Pydantic v2** | Type-safe SwarmEvent models |
| **PostgreSQL 15** | Primary data store with native partitioning |
| **PostGIS 3** | Spatial queries (GIST indexes, Polygon, LineString, PointZ, Raster) |
| **YOLOv8 (Ultralytics)** | Deep learning object detection in CERES |
| **OpenCV** | Image processing pipeline in CERES |
| **`schedule` library** | Lightweight Oracle scheduler |
| **Next.js 15** | Pilot Portal — receives webhooks, renders real-time dashboard |
| **TypeScript** | Type-safe portal frontend |
| **Requests** | Webhook HTTP dispatch from Swarm to Portal |

---

## 🧭 End-to-End Example

> **Scenario:** Satellite detects sudden NDVI drop on Fazenda Boa Vista (Goiás). A Spittlebug outbreak is suspected.

```
1. [Oracle]       → Publishes oracle.satellite.ndvi_update (ndvi_delta: -22%)
2. [Swarm Bus]    → Routes event to SOLIS
3. [SOLIS]        → Detects >15% NDVI drop. Publishes solis.directive.dispatch_ceres
4. [Swarm Bus]    → Routes event to MERCURIUS
5. [MERCURIUS]    → Calculates ROI: 15 tons × R$150 = R$2,250 save vs. R$450 cost → Approved
6. [MERCURIUS]    → Publishes mercurius.directive.approved
7. [Swarm Bus]    → Routes event to CERES
8. [CERES]        → Publishes portal.mission.approved (budget: R$450)
9. [Webhook]      → HTTP POST to Next.js portal
10. [Portal]      → Pilot sees: "Financial clearance granted. Authorized to fly Fazenda Boa Vista."
11. [FAUNA]       → (Simultaneously) Accumulated Degree Days: 451 > threshold
12. [FAUNA]       → Publishes fauna.alert.pest_emergence (Spittlebug, confidence: 89%)
13. [Portal]      → Pilot sees: "Spittlebug nymph emergence predicted. PEST_DAMAGE_ASSESSMENT mission recommended."
```

The pilot gets the complete picture — satellite anomaly, finance approval, and biological timing — all **autonomously**.

---

## 🌱 The Bigger Vision

Agrosul-Tech is not a drone software tool — it's a **precision agriculture operating system**:

- Every farm plot in Brazil has a real-time digital twin in PostGIS
- The AI Swarm monitors 24/7 across weather, market, satellite, and pest dimensions
- Human pilots and agronomists focus on **execution** — the AI handles decision-making and timing
- Prescriptions generated autonomously, formatted for ISO-XML tractor auto-steer systems
- Carbon credit MRV (Monitoring, Reporting, Verification) generated automatically from flight data

---

*Agrosul-Tech Platform | Monorepo v1.0 | June 2026*  
*"Precision agriculture at the speed of AI, executed by the hands of expertise."*
