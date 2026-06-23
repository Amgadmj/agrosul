<#
.SYNOPSIS
Imports a GeoTIFF Digital Elevation Model (DEM) into the PostGIS database.

.DESCRIPTION
This script uses raster2pgsql to tile a large GeoTIFF file and import it into a staging table, 
then copies the tiles into the main 'digital_elevation_hydrology' table alongside the specified region name.
It implements the 100x100 tiling best practice for rapid spatial querying.

.EXAMPLE
.\import_dem.ps1 -TiffPath "C:\data\farm_dem.tif" -RegionName "Gleba Norte"
#>
param (
    [Parameter(Mandatory=$true)]
    [string]$TiffPath,

    [Parameter(Mandatory=$true)]
    [string]$RegionName,

    [string]$DbName = "postgres",
    [string]$DbUser = "postgres",
    [string]$DbHost = "localhost",
    [string]$DbPort = "5432"
)

$ErrorActionPreference = "Stop"

# Ensure raster2pgsql is available
if (!(Get-Command "raster2pgsql" -ErrorAction SilentlyContinue)) {
    Write-Error "raster2pgsql command not found. Please ensure PostGIS bin folder is in your PATH."
}
if (!(Get-Command "psql" -ErrorAction SilentlyContinue)) {
    Write-Error "psql command not found. Please ensure PostgreSQL bin folder is in your PATH."
}

Write-Host "Tile generating and importing into staging table..." -ForegroundColor Cyan

# 1. Generate SQL for the staging table
# -s 4326 : Set SRID to WGS84
# -I : Create GIST spatial index
# -C : Apply raster constraints for PostGIS tools
# -M : Vacuum analyze the table
# -t 100x100 : Cut the raster into 100x100 pixel tiles
# -f dem_raster : Name of the raster column
# -d : Drop the staging table if it already exists, then create
$stagingSqlFile = ".\temp_staging_dem.sql"
raster2pgsql -s 4326 -I -C -M -t 100x100 -f dem_raster -d $TiffPath public.staging_dem_import > $stagingSqlFile

# 2. Execute the staging SQL
Write-Host "Running staging SQL against database '$DbName'..." -ForegroundColor Cyan
psql -U $DbUser -h $DbHost -p $DbPort -d $DbName -f $stagingSqlFile

# 3. Migrate from staging to the main table
Write-Host "Migrating tiled data to the main digital_elevation_hydrology table..." -ForegroundColor Cyan

$migrateQuery = @"
BEGIN;
-- Insert tiles from staging table to our main table, stamping them with the Region Name
INSERT INTO digital_elevation_hydrology (region_name, dem_raster)
SELECT '$RegionName', dem_raster
FROM staging_dem_import;

-- Drop the temporary staging table
DROP TABLE staging_dem_import;
COMMIT;
"@

$migrateQuery | psql -U $DbUser -h $DbHost -p $DbPort -d $DbName

# Cleanup
Remove-Item $stagingSqlFile -Force

Write-Host "======================================================" -ForegroundColor Green
Write-Host "SUCCESS: Imported $TiffPath into '$RegionName'!" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
