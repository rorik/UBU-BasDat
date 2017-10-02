/*	Práctica 3 - Bases de Datos UBU
 *	Alumnos:
 *		- Rodrigo Díaz García
 */

DROP TABLE IF EXISTS practica3 CASCADE;

CREATE TABLE practica3(
	nombre VARCHAR(60)	CONSTRAINT PK_empleadoNombre PRIMARY KEY 	NOT NULL,
	contrato DATE		NOT NULL,
	ventas NUMERIC(7,1)	CONSTRAINT CHK_empleadoVentas CHECK (ventas >= 0)
);

INSERT INTO practica3	(	nombre, 		contrato,		ventas)
	VALUES		(	'Belén Sierra',		DATE '2016-11-21',	184.1),
			(	'Armando Terrazas',	DATE '2016-11-21',	4621.5),
			(	'Clotilde Trujillo',	DATE '2016-11-21',	10),
			(	'Paula Bolívar',	CURRENT_DATE,		null),
			(	'Odalis Cuesta',	DATE '2016-04-14',	205050.5),
			(	'Albina Maradona',	DATE '2017-05-15',	333.3),
			(	'Rosalia Rivero',	DATE '2017-09-30',	10),
			(	'Alonso Villanueva',	DATE '2017-07-17',	6464.6),
			(	'Jimena Escobar',	DATE '2017-09-25',	13),
			(	'Álvaro Quintana',	DATE '2017-08-18',	1942);

/* PRIMERA VISTA */

CREATE VIEW primeraVista ( nombre, contrato, ventas) AS
	SELECT nombre, contrato, ventas
	FROM practica3
	WHERE ventas >= 1000;

-- 1:
SELECT * FROM primeraVista;
-- 2:
DELETE FROM primeraVista WHERE nombre = 'Álvaro Quintana'; -- No produce error
--SELECT * FROM primeraVista WHERE nombre = 'Álvaro Quintana'; -- Elimina correctamente una fila
--SELECT * FROM practica3 WHERE nombre = 'Álvaro Quintana'; -- También elimina la fila de la tabla
-- 3:
UPDATE primeraVista SET ventas = ventas + 1 WHERE nombre = 'Alonso Villanueva'; -- No produce error
--SELECT * FROM primeraVista WHERE nombre = 'Alonso Villanueva'; -- Modifica correctamente una fila
--SELECT * FROM practica3 WHERE nombre = 'Alonso Villanueva'; -- También modifica la tabla
-- 4:
INSERT INTO primeraVista	(nombre, 	contrato,	ventas)
	values			('Félix Grande', DATE '2017-01-20', 8192); -- No produce error
--SELECT * FROM primeraVista WHERE nombre = 'Félix Grande'; -- Inserta correctamente una fila en la vista
--SELECT * FROM practica3 WHERE nombre = 'Félix Grande'; -- También inserta la fila en la tabla
-- 5:
UPDATE primeraVista SET ventas = 500 WHERE nombre = 'Armando Terrazas';
-- 6:
INSERT INTO primeraVista	(nombre, contrato, ventas)
	VALUES			('Julio Campos', DATE '2017-10-01', 32); -- No produce error
--SELECT * FROM primeraVista WHERE nombre = 'Julio Campos'; -- No se muestra en la vista
--SELECT * FROM practica3 WHERE nombre = 'Julio Campos'; -- Pero sí en la tabla

/* SEGUNDA VISTA */

CREATE VIEW segundaVista ( nombre, contrato, ventasDiarias) AS
	SELECT nombre, contrato, ventas / DATE_DIST(CURRENT_DATE, contrato)
	FROM practica3
	WHERE DATE_DIST(CURRENT_DATE, contrato) >= 30;

-- 7:
SELECT * FROM segundaVista;
-- 8:
DELETE FROM segundaVista WHERE nombre = 'Belén Sierra'; -- No produce error
--SELECT * FROM segundaVista WHERE nombre = 'Belén Sierra'; -- Elimina fila de la vista
--SELECT * FROM practica3 WHERE nombre = 'Belén Sierra'; -- Elimina fila de la tabla
-- 9:
UPDATE segundaVista SET nombre = 'Armando Terrazas Fernandez', contrato = contrato + 31 WHERE nombre = 'Armando Terrazas'; -- No produce error
--SELECT * FROM segundaVista WHERE nombre = 'Armando Terrazas Fernandez'; -- Modifica la vista
--SELECT * FROM practica3 WHERE nombre = 'Armando Terrazas Fernandez'; -- Modifica la tabla
-- 10:
--UPDATE segundaVista SET ventasDiarias = 350 WHERE nombre = 'Alonso Villanueva'; -- Produce error: "View columns that are not columns of their base relation are not updatable"
-- 11:
--INSERT INTO segundaVista (nombre, contrato, ventasDiarias) VALUES ('Miss Lee Zal', DATE '2016-11-4', 15); -- Produce error

/* TERCERA VISTA */
CREATE VIEW terceraVista ( nombre, contrato, ventas) AS
	SELECT DISTINCT nombre, contrato, ventas
	FROM practica3
	WHERE ventas < 400;

-- 12:
SELECT * FROM terceraVista;
-- 13:
--DELETE FROM terceraVista WHERE nombre = 'Belén Sierra'; -- Produce error: "Views containing DISTINCT are not automatically updatable"
-- 14:
--UPDATE terceraVista SET ventas = 400 WHERE ventas > 400; -- Produce error
-- 15:
--INSERT INTO terceraVista (nombre, contrato, ventas) VALUES ('Pastor Lul', CURRENT_DATE, 0); -- Produce error
