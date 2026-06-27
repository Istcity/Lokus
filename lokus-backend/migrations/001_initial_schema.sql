CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS parcels (
    id SERIAL PRIMARY KEY,
    il_kodu VARCHAR(2),
    ilce_kodu VARCHAR(4),
    mahalle_kodu VARCHAR(12),
    ada VARCHAR(10),
    parsel VARCHAR(10),
    yuzolcum NUMERIC(12,2),
    malik_ozet VARCHAR(255),
    geom GEOMETRY(POLYGON, 4326),
    son_guncelleme TIMESTAMP,
    kaynak VARCHAR(100)
);
CREATE INDEX IF NOT EXISTS idx_parcels_geom ON parcels USING GIST(geom);

CREATE TABLE IF NOT EXISTS zoning_plans (
    id SERIAL PRIMARY KEY,
    il_kodu VARCHAR(2),
    plan_notu TEXT,
    taks NUMERIC(4,2),
    kaks NUMERIC(4,2),
    yapilasma_turu VARCHAR(50),
    confidence_level VARCHAR(10) DEFAULT 'medium',
    geom GEOMETRY(MULTIPOLYGON, 4326),
    son_guncelleme TIMESTAMP,
    kaynak_kurum VARCHAR(150),
    veri_hash VARCHAR(64)
);
CREATE INDEX IF NOT EXISTS idx_zoning_geom ON zoning_plans USING GIST(geom);

CREATE TABLE IF NOT EXISTS infrastructure (
    id SERIAL PRIMARY KEY,
    tur VARCHAR(30),
    geom GEOMETRY(LINESTRING, 4326),
    kaynak VARCHAR(100),
    son_guncelleme TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_infra_geom ON infrastructure USING GIST(geom);

CREATE TABLE IF NOT EXISTS etl_update_log (
    id SERIAL PRIMARY KEY,
    source_name VARCHAR(100),
    records_upserted INT,
    data_hash VARCHAR(64),
    started_at TIMESTAMP,
    finished_at TIMESTAMP,
    status VARCHAR(20)
);
