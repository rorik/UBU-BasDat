/*	Práctica 4 - Bases de Datos UBU
 *	Alumnos:
 *		- Rodrigo Díaz García
 */

DROP TABLE IF EXISTS
    clientes,
    facturas,
    lineasDeFactura,
    formasDePago,
    tiposDeClientes,
    provincias,
    ciudades,
    color,
    productos
CASCADE;


CREATE TABLE formasDePago (
    acronimo CHAR (20)	CONSTRAINT PK_formasDePago PRIMARY KEY,
    descripcion CHAR (100)
);
CREATE TABLE tiposDeClientes (
    acronimo CHAR (20)	CONSTRAINT PK_tiposDeClientes PRIMARY KEY,
    descripcion CHAR (100)
);
CREATE TABLE provincias (
    acronimo CHAR (6)		CONSTRAINT PK_provincias PRIMARY KEY,
    descripcion CHAR (20)	NOT NULL,
    CONSTRAINT CHK_provinciaMayus CHECK (acronimo = UPPER(acronimo))
);
CREATE TABLE ciudades (
    nombre CHAR (20),
    provincia CHAR (6)	CONSTRAINT REF_ciudadesProvincia REFERENCES provincias (acronimo) ON UPDATE CASCADE,
    CONSTRAINT PK_ciudades PRIMARY KEY (nombre, provincia)
);
CREATE TABLE clientes (
    CIF INTEGER			CONSTRAINT PK_clientes PRIMARY KEY,
    nombre CHAR (40)		NOT NULL,
    direccion CHAR (60),
    telefono CHAR (20)		CONSTRAINT CHK_clienteTlf CHECK (telefono IS NULL OR CHAR_LENGTH(telefono) >= 9),
    numeroFax CHAR (20)		CONSTRAINT CHK_clienteFax CHECK (numeroFax IS NULL OR CHAR_LENGTH(numeroFax) >= 9),
    email CHAR (30),
    numeroCuenta INTEGER,
    formaDePago CHAR (20)	CONSTRAINT REF_clientesPago REFERENCES formasDePago (acronimo) ON UPDATE CASCADE,
    ciudad CHAR (20)		NOT NULL,
    privincia CHAR (6)		NOT NULL,
    tipo CHAR (20) 		CONSTRAINT REF_clientesTipo REFERENCES tiposDeClientes (acronimo) ON UPDATE CASCADE DEFAULT 'NEW' NOT NULL,
    CONSTRAINT FK_clientesCiudad FOREIGN KEY (ciudad, privincia) REFERENCES ciudades (nombre, provincia) ON UPDATE CASCADE,
    CONSTRAINT CHK_metodoContacto CHECK (direccion || telefono || numeroFax || email != '')
);
CREATE TABLE facturas (
    id SERIAL			CONSTRAINT PK_facturas PRIMARY KEY,
    fecha TIMESTAMP		NOT NULL	DEFAULT CURRENT_TIMESTAMP,
    cliente INTEGER		CONSTRAINT REF_facturaCliente REFERENCES clientes (CIF)	NOT NULL,
    formaDePago CHAR (20)	CONSTRAINT REF_facturaPago REFERENCES formasDePago (acronimo) ON UPDATE CASCADE
);
CREATE TABLE color (
    nombre CHAR (30)	CONSTRAINT PK_color PRIMARY KEY,
    r INTEGER		NOT NULL	CONSTRAINT CHK_colorR CHECK (r BETWEEN 0 AND 255),
    g INTEGER		NOT NULL	CONSTRAINT CHK_colorG CHECK (g BETWEEN 0 AND 255),
    b INTEGER		NOT NULL	CONSTRAINT CHK_colorB CHECK (b BETWEEN 0 AND 255),
    CONSTRAINT UNQ_colorRGB UNIQUE (r, g, b)
);
CREATE TABLE productos (
    familia CHAR (20),
    referencia INTEGER,
    color CHAR (30)	CONSTRAINT REF_productosColor REFERENCES color (nombre)	ON UPDATE CASCADE,
    existencias INTEGER	CONSTRAINT CHK_existenciasPos CHECK (existencias >= 0)	DEFAULT 0,
    CONSTRAINT PK_productos PRIMARY KEY (familia, referencia, color)
);
CREATE TABLE lineasDeFactura (
    numeroFactura INTEGER	CONSTRAINT REF_lineaFactura REFERENCES facturas (id) ON DELETE CASCADE NOT NULL,
    linea SERIAL		CONSTRAINT CHK_lineaPos CHECK (linea >= 0),
    productoFamilia CHAR (20)	NOT NULL,
    productoReferencia INTEGER	NOT NULL,
    productoColor CHAR (30)	NOT NULL,
    cantidad INTEGER		CONSTRAINT CHK_cantidadPos CHECK (cantidad >= 0) NOT NULL,
    precio NUMERIC (8,3)	CONSTRAINT CHK_precioPos CHECK (precio >= 0) NOT NULL,
    CONSTRAINT PK_lineasDeFactura
    	PRIMARY KEY (numeroFactura, linea),
    CONSTRAINT FK_productos
    	FOREIGN KEY (productoFamilia, productoReferencia, productoColor)
    	REFERENCES productos (familia, referencia, color)
    	ON DELETE CASCADE
    	ON UPDATE CASCADE
);

INSERT INTO formasDePago (acronimo, descripcion)
	VALUES  ('VISA', 'Tarjeta de crédito VISA'),
		('MC', 'Tarjeta de crédito MasterCard'),
		('DOM', 'Domiciliación bancaria'),
		('TRANS', 'Transferencia bancaria');

INSERT INTO tiposDeClientes (acronimo, descripcion)
	VALUES  ('NEW', 'Nuevo cliente, sin información'),
	    	('GRAN', 'Cliente que mueve más del 10% del capital'),
	    	('PEQ', 'Cliente que mueve más del 1% del capital'),
	    	('MIN', 'Cliente que no mueve mucho capital');

INSERT INTO provincias (acronimo, descripcion)
	VALUES  ('BUR', 'Burgos'),
	    	('MAD', 'Madrid'),
	    	('BAR', 'Barcelona');

INSERT INTO ciudades (nombre, provincia)
	VALUES  ('Burgos', 'BUR'),
	    	('Poza de la Sal', 'BUR'),
	    	('Las Rozas', 'MAD');

INSERT INTO clientes (CIF, nombre, direccion, telefono, numeroFax, email, numeroCuenta, formaDePago, ciudad, privincia, tipo)
	VALUES  (	49812,
			'Hierros Pepe',
			'Calle Victoria 1234, 2º C',
			NULL,
			NULL,
			'pepe@hpepe.bur',
			123456,
			'DOM',
			'Burgos',
			'BUR',
			'PEQ'
		),
		(	111,
			'Amazonas',
			'Avenida Imaginaria -3.1415',
			'123456789',
			'123456789#22',
			'ventas@amazonas.amz',
			10,
			'TRANS',
			'Las Rozas',
			'MAD',
			'GRAN'
		);

INSERT INTO facturas (fecha, cliente, formaDePago)
	VALUES  (CURRENT_TIMESTAMP,	111,	'TRANS'),
	    	(CURRENT_TIMESTAMP - INTERVAL '16 days',	111,	'TRANS'),
	    	(CURRENT_TIMESTAMP,	49812,	'DOM');

INSERT INTO color (nombre, r, g, b)
	VALUES  ('Rojo',	255,	0,	0),
	    	('Azul Marino', 28,	107,	160),
	    	('Hierba',	0,	123,	12);

INSERT INTO productos (familia, referencia, color, existencias)
	VALUES 	('Mesas',	121314,	'Rojo',		300),
	    	('Mesas',	121314,	'Azul Marino',	200),
	    	('Sillas',	9876,	'Hierba',	15);

INSERT INTO lineasDeFactura (numeroFactura, linea, productoFamilia, productoReferencia, productoColor, cantidad, precio)
	VALUES  (1,	1,	'Sillas',	9876,	'Hierba',	12,	42.333),
	    	(2,	1,	'Mesas',	121314,	'Rojo',		142,	120),
	    	(2,	2,	'Mesas',	121314,	'Azul Marino',	142,	120);

-- DELETE en cascada de facturas:
SELECT * FROM lineasDeFactura WHERE numeroFactura = 2;
DELETE FROM facturas WHERE id = 2;
SELECT * FROM lineasDeFactura WHERE numeroFactura = 2;

-- UPDATE en cascada de color:
SELECT * FROM productos WHERE referencia = 9876;
UPDATE color SET nombre = 'Verde Hierba' WHERE nombre = 'Hierba';
SELECT * FROM productos WHERE referencia = 9876;

-- UPDATE en cascada de provincia:
SELECT * FROM clientes;
UPDATE provincias SET acronimo = 'BURG' WHERE descripcion = 'Burgos';
SELECT * FROM clientes;

-- UPDATE en cascada de forma de pago:
SELECT * FROM formasDePago;
UPDATE formasDePago SET acronimo = 'DOMBAN' WHERE acronimo = 'DOM';
SELECT * FROM formasDePago;

-- UPDATE en cascada de tipo de cliente:
SELECT * FROM clientes WHERE CIF = 111;
UPDATE tiposDeClientes SET acronimo = 'BIG' WHERE acronimo = 'GRAN';
SELECT * FROM clientes WHERE CIF = 111;

-- ERROR FK INSERT:
--INSERT INTO productos (familia, referencia, color) VALUES ('Puertas',	444,	'Marrón');

-- ERROR FK DELETE:
--DELETE FROM color WHERE r > 200;

-- ERROR FK UPDATE:
--UPDATE clientes SET CIF = 222 WHERE CIF = 111;
