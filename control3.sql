-- Grupo 4
-- Esteban Glochon
-- Andres Ijura
-- Leonardo Muñoz
-- Gonzalo Ordenes

-- Agregamos la columna de geometria a la tabla de zonas_censales_gs

SELECT AddGeometryColumn('minimarkets_gs', 'geometria', 4326, 'POINT', 2);

UPDATE minimarkets_gs
	SET geometria = ST_setsrid( ST_MakePoint(minimarkets_gs.longitud, minimarkets_gs.latitud), 4326);
	
-------------------------------------------------------------------------------------------------------------------

-- Creamos la vista de las zonas censales que estan a menos de 500 metros de un minimarket
CREATE OR REPLACE VIEW minus_500m AS
	SELECT zonas_censales_gs.geom 
	FROM zonas_censales_gs, minimarkets_gs
	WHERE  ST_Distance(zonas_censales_gs.geom, ST_Transform(minimarkets_gs.geometria, 32719)) < 500;
	
ALTER VIEW minus_500m RENAME COLUMN geom TO geometria;


-- Creamos la tabla de las zonas censales que estan a mas de 500 metros de un minimarket
CREATE TABLE zc_500m AS (
    SELECT *
    FROM zonas_censales_gs
    LEFT JOIN minus_500m
    ON zonas_censales_gs.geom = minus_500m.geometria
    WHERE minus_500m.geometria is null
);

-- Se elimina la vista utilizada para la creacion de la tabla
DROP VIEW minus_500m;
-------------------------------------------------------------------------------------------------------------------

-- Creamos la vista que contiene el total de zonas censales por comuna
CREATE OR REPLACE VIEW total_por_comunas AS
	SELECT COUNT(*) as zonas_por_comuna, zona.nom_comuna as nombre_comuna
		FROM zonas_censales_gs as zona
		GROUP BY zona.nom_comuna;


-- Creamos la vista que contiene el numero de zonas censales a mas de 500 metros por comuna
CREATE OR REPLACE VIEW zonas_minimarket AS
	SELECT COUNT(*) AS zona_500, zc_500m.nom_comuna
		FROM zc_500m
		GROUP BY zc_500m.nom_comuna;
	

-- Creamos la vista que contiene el porcentaje de zonas censales a menos de 500 metros por comuna
CREATE OR REPLACE VIEW porcentajes AS
	SELECT ((zonas_minimarket.zona_500 * 100.0)/ total_por_comunas.zonas_por_comuna) AS porcentaje, total_por_comunas.nombre_comuna, total_por_comunas.zonas_por_comuna, zonas_minimarket.zona_500
		FROM total_por_comunas, zonas_minimarket
		WHERE total_por_comunas.nombre_comuna = zonas_minimarket.nom_comuna;
	   
-- Creamos la tabla que contiene el porcentaje de zonas censales a mas de 500m por comuna
CREATE TABLE comuna_ptje_mini AS(
	SELECT zonas_censales_gs.nom_comuna, ST_union(zonas_censales_gs.geom) as Geometria_comuna, porcentajes.porcentaje
    	FROM zonas_censales_gs, porcentajes
		WHERE porcentajes.nombre_comuna = zonas_censales_gs.nom_comuna
    	GROUP BY zonas_censales_gs.nom_comuna, porcentajes.porcentaje
);

-- Se elimina las vistas utilizadas para la creacion de la tabla
DROP VIEW total_por_columnas;
DROP VIEW zona_minimarket;
DROP VIEW procentajes;

