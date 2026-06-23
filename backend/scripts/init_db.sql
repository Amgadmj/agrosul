-- ==============================================================================
-- Agrosul Autonomous Agriculture Platform - Master Database Architecture
-- Phase 1 & 1.5: Spatial Data Foundation & Multi-Tenant Enterprise Logic
-- ==============================================================================

-- 1. Enable Spatial Extensions
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_raster;

-- ==============================================================================
-- 2. THE MULTI-TENANT HIERARCHY
-- Top-down structure for data isolation across mega-producers
-- ==============================================================================

CREATE TABLE IF NOT EXISTS producers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS farms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    total_area_ha DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Strict geometric primitive for farm operational boundaries
CREATE TABLE IF NOT EXISTS farm_plots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    crop_type VARCHAR(100),
    plot_polygon GEOMETRY(Polygon, 4326) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_farm_plots_geom ON farm_plots USING GIST (plot_polygon);


-- ==============================================================================
-- 3. MULTI-DIMENSIONAL REALITY TABLES (Linked to Hierarchy)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS digital_elevation_hydrology (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_plot_id UUID NOT NULL REFERENCES farm_plots(id) ON DELETE CASCADE,
    region_name VARCHAR(255) NOT NULL,
    dem_raster RASTER,
    dem_polygon GEOMETRY(Polygon, 4326),
    flow_line GEOMETRY(LineString, 4326),
    slope_gradient_percent DECIMAL(5,2),
    runoff_direction_degrees DECIMAL(6,2),
    recorded_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_deh_raster_gist ON digital_elevation_hydrology USING GIST (ST_ConvexHull(dem_raster));
CREATE INDEX IF NOT EXISTS idx_deh_dem_gist ON digital_elevation_hydrology USING GIST (dem_polygon);
CREATE INDEX IF NOT EXISTS idx_deh_flow_gist ON digital_elevation_hydrology USING GIST (flow_line);


CREATE TABLE IF NOT EXISTS socio_legal_boundaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_id UUID NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    boundary_type VARCHAR(100) NOT NULL, 
    boundary_name VARCHAR(255) NOT NULL,
    description TEXT,
    boundary_polygon GEOMETRY(Polygon, 4326) NOT NULL,
    restriction_level VARCHAR(50), 
    active_from DATE,
    active_until DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_socio_legal_geom_gist ON socio_legal_boundaries USING GIST (boundary_polygon);


CREATE TABLE IF NOT EXISTS soil_mechanics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_plot_id UUID NOT NULL REFERENCES farm_plots(id) ON DELETE CASCADE,
    zone_polygon GEOMETRY(Polygon, 4326) NOT NULL,
    clay_percentage DECIMAL(5,2) CHECK (clay_percentage >= 0 AND clay_percentage <= 100),
    silt_percentage DECIMAL(5,2) CHECK (silt_percentage >= 0 AND silt_percentage <= 100),
    sand_percentage DECIMAL(5,2) CHECK (sand_percentage >= 0 AND sand_percentage <= 100),
    load_bearing_capacity_kpa DECIMAL(10,2),
    compaction_risk_index VARCHAR(50), 
    sampled_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_soil_mech_geom_gist ON soil_mechanics USING GIST (zone_polygon);


CREATE TABLE IF NOT EXISTS field_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_plot_id UUID NOT NULL REFERENCES farm_plots(id) ON DELETE CASCADE,
    note_text TEXT NOT NULL,
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);


-- ==============================================================================
-- 4. HYPER-OPTIMIZED TIME-SERIES: Flight Telemetry
-- Using Native PostgreSQL Partitioning (By Month) for millions of drone pings
-- ==============================================================================

CREATE TABLE IF NOT EXISTS flight_telemetry (
    id UUID DEFAULT gen_random_uuid(),
    farm_plot_id UUID NOT NULL, -- Cannot be standard foreign key if we partition on timestamp without it in PK, but we handle integrity at app layer
    mission_id UUID NOT NULL,
    drone_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
    location GEOMETRY(PointZ, 4326) NOT NULL, -- 3D coordinates: Longitude, Latitude, Altitude
    battery_percentage DECIMAL(5,2),
    speed_ms DECIMAL(6,2),
    heading_degrees DECIMAL(6,2),
    PRIMARY KEY (id, timestamp)
) PARTITION BY RANGE (timestamp);

-- Example native partitions (These would be dynamically created by a cron job in production via pg_partman)
CREATE TABLE flight_telemetry_2026_05 PARTITION OF flight_telemetry FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE flight_telemetry_2026_06 PARTITION OF flight_telemetry FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');

CREATE INDEX IF NOT EXISTS idx_flight_telemetry_geom ON flight_telemetry USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_flight_telemetry_time ON flight_telemetry (timestamp DESC);


-- ==============================================================================
-- 5. ENTERPRISE ROW-LEVEL SECURITY (RLS)
-- Ensures strict data isolation. 
-- App backend MUST run: `SET LOCAL app.tenant_id = 'producer_uuid';`
-- ==============================================================================

ALTER TABLE producers ENABLE ROW LEVEL SECURITY;
ALTER TABLE farms ENABLE ROW LEVEL SECURITY;
ALTER TABLE farm_plots ENABLE ROW LEVEL SECURITY;
ALTER TABLE digital_elevation_hydrology ENABLE ROW LEVEL SECURITY;
ALTER TABLE socio_legal_boundaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE soil_mechanics ENABLE ROW LEVEL SECURITY;
ALTER TABLE field_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE flight_telemetry ENABLE ROW LEVEL SECURITY;

CREATE POLICY producer_isolation ON producers 
    USING (id = current_setting('app.tenant_id')::UUID);

CREATE POLICY farm_isolation ON farms 
    USING (producer_id = current_setting('app.tenant_id')::UUID);

CREATE POLICY farm_plot_isolation ON farm_plots 
    USING (farm_id IN (SELECT id FROM farms WHERE producer_id = current_setting('app.tenant_id')::UUID));

CREATE POLICY deh_isolation ON digital_elevation_hydrology
    USING (farm_plot_id IN (SELECT fp.id FROM farm_plots fp JOIN farms f ON fp.farm_id = f.id WHERE f.producer_id = current_setting('app.tenant_id')::UUID));

CREATE POLICY socio_legal_isolation ON socio_legal_boundaries
    USING (farm_id IN (SELECT id FROM farms WHERE producer_id = current_setting('app.tenant_id')::UUID));

CREATE POLICY soil_mechanics_isolation ON soil_mechanics
    USING (farm_plot_id IN (SELECT fp.id FROM farm_plots fp JOIN farms f ON fp.farm_id = f.id WHERE f.producer_id = current_setting('app.tenant_id')::UUID));

CREATE POLICY field_notes_isolation ON field_notes
    USING (farm_plot_id IN (SELECT fp.id FROM farm_plots fp JOIN farms f ON fp.farm_id = f.id WHERE f.producer_id = current_setting('app.tenant_id')::UUID));

CREATE POLICY telemetry_isolation ON flight_telemetry
    USING (farm_plot_id IN (SELECT fp.id FROM farm_plots fp JOIN farms f ON fp.farm_id = f.id WHERE f.producer_id = current_setting('app.tenant_id')::UUID));


-- ==============================================================================
-- 6. PHASE 2.5: THE GLOBAL DATA ORACLE
-- Tables to store external API integrations (Weather, Market, Macro-News)
-- ==============================================================================

CREATE TABLE IF NOT EXISTS oracle_weather_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farm_plot_id UUID NOT NULL REFERENCES farm_plots(id) ON DELETE CASCADE,
    temp_c DECIMAL(5,2),
    precipitation_mm DECIMAL(6,2),
    humidity DECIMAL(5,2),
    wind_speed_ms DECIMAL(5,2),
    forecast_type VARCHAR(50), -- e.g., 'HISTORICAL', 'LIVE', 'PREDICTION'
    timestamp TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS oracle_market_prices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    commodity VARCHAR(100) NOT NULL, -- e.g., 'Sugarcane', 'Soybean'
    exchange VARCHAR(100), -- e.g., 'CBOT', 'B3'
    price_brl DECIMAL(10,2) NOT NULL,
    contract_date DATE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS oracle_agronomic_news (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_url VARCHAR(500),
    headline TEXT NOT NULL,
    -- Sophisticated NLP Extraction Vectors
    impact_category VARCHAR(100), -- 'Logistics', 'Weather', 'Economic', 'Regulatory'
    affected_commodities TEXT[], -- ['Sugarcane', 'Soybean']
    sentiment_blob JSONB, -- { "positive": 0.2, "negative": 0.8, "keywords": [...] }
    geospatial_relevance GEOMETRY(Polygon, 4326), -- If the news specifies a region like 'Mato Grosso'
    published_at TIMESTAMP WITH TIME ZONE NOT NULL,
    ingested_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_oracle_news_geom ON oracle_agronomic_news USING GIST (geospatial_relevance);


-- ==============================================================================
-- 7. PHASE 4: REAL-TIME ADVISORY ENGINE
-- Webhook notifications dispatched from the Swarm to the Pilot Dashboard
-- ==============================================================================

CREATE TABLE IF NOT EXISTS portal_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    producer_id UUID NOT NULL REFERENCES producers(id) ON DELETE CASCADE,
    agent_source VARCHAR(50) NOT NULL, -- e.g., 'Aero', 'Solis', 'Ceres'
    topic VARCHAR(255) NOT NULL, -- e.g., 'portal.notification.urgent'
    message TEXT NOT NULL,
    payload JSONB,
    priority VARCHAR(50) DEFAULT 'INFO',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
-- We should enable RLS here as well, so pilots only see notifications for their producer
ALTER TABLE portal_notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY notification_isolation ON portal_notifications 
    USING (producer_id = current_setting('app.tenant_id')::UUID);
