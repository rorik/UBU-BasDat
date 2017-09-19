/*	Práctica 2 - Bases de Datos UBU
 *	Alumnos:
 *		- Rodrigo Díaz García
 */

DROP TABLE IF EXISTS practica2;

CREATE TABLE practica2(
	id INTEGER		CONSTRAINT PK_prodId PRIMARY KEY		CONSTRAINT CHK_prodId CHECK (id >= 0),
	nombre VARCHAR(30)	CONSTRAINT UNQ_prodNombre UNIQUE		NOT NULL,
	coste NUMERIC(5,2)	CONSTRAINT CHK_prodCoste CHECK (coste >= 0)	NOT NULL,
	venta NUMERIC(5,2)	CONSTRAINT CHK_prodVenta CHECK (venta >= 0)	NOT NULL,
	reposicion DATE		DEFAULT CURRENT_DATE				NOT NULL
);

INSERT INTO practica2	(	id, 	nombre,				coste,	venta,	reposicion)
	values		(	10,	'Arroz blanco (10kg)',		14.04,	17.95,	DATE '2017-08-10'),
			(	11,	'Papel de colores (2000u)',	121,	99.95,	DATE '2013-11-30'),
			(	2,	'DVD R/W (100u)',		249.8,	74.49,	DATE '2006-02-27'),
			(	3,	'Aire comprimido (10L)',	8.91,	109.99,	DATE '2016-09-01'),
			(	14,	'Queso Parmesano (20kg)',	155.55,	155.55,	DATE '2017-01-22'),
			(	15,	'Monedas Oro (22k)',		202.02,	199.99,	DATE '1995-03-15'),
			(	16,	'Nintendo SNES (PAL)',		54,	256,	DATE '1993-06-16'),
			(	17,	'Fotocopiadora (3x53Sf)',	173.44,	208,	DATE '2013-07-04'),
			(	8,	'Auriculares (22ohm)',		246.1,	295.95,	DATE '2015-12-20');

SELECT * FROM practica2 -- Función periódica con periodo vertical 200
	WHERE 	venta % 200 < 100 AND coste < 200 -- (0,2k) y (1,2k)
		OR venta % 200 >= 100 AND coste >= 100 AND coste < 300; -- (1,1+2k) y (2,1+2k)
SELECT * FROM practica2 -- Simetría impar en eje x con centro (150,200) para y>=100 + bloque y<100
	WHERE 	venta <100 AND coste<200 -- Primera fila, dos primeras columnas
 		OR venta >= 100 AND venta <= 300 AND coste < 300 -- Segunda y tercera fila
		AND NOT venta - venta % 100 + coste - coste % 100 = 100 -- Excepto (0,1)
		AND NOT venta - venta % 100 + coste - coste % 100 = 400;-- Excepto (2,2)
SELECT * FROM practica2 -- Simetría par en y=x + bloque x<200
	WHERE 	venta - venta % 100 + coste - coste % 100 = 300 -- (1,2) y (2,1)
 		OR coste < 200 AND venta <= 300 -- Primera y segunda columna
		AND NOT (venta - venta % 100 = 100 AND coste < 100); -- Excepto (0,1)
SELECT * FROM practica2 -- Bloque x<200
	WHERE	coste < 200 AND venta <= 300 -- Primera y segunda columna
		AND NOT (coste < 100 AND venta < 200 AND venta >= 100) -- Excepto (0,1)
		OR coste >= 200 AND venta < 200 AND venta >= 100; -- (2,1)
SELECT * FROM practica2 -- Bloque x<300
	WHERE	coste < 300 AND venta <= 300 -- Primera y segunda columna
		AND NOT (coste < 100 AND venta < 200 AND venta >= 100) -- Excepto (0,1)
		AND NOT (coste >=200 AND venta < 100) -- Excepto (2,0)
		AND NOT (coste >=200 AND venta >= 200 AND venta <= 300); -- Excepto (2,2)