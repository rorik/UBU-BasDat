/*	Práctica 5 - Bases de Datos UBU
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
    productos,
    clientesRelacionTipos,
    clientesRelacionPago
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
    formaDePagoDef CHAR (20)	CONSTRAINT REF_clientesPago REFERENCES formasDePago (acronimo) ON UPDATE CASCADE NOT NULL,
    ciudad CHAR (20)		NOT NULL,
    privincia CHAR (6)		NOT NULL,
    CONSTRAINT FK_clientesCiudad FOREIGN KEY (ciudad, privincia) REFERENCES ciudades (nombre, provincia) ON UPDATE CASCADE,
    CONSTRAINT CHK_metodoContacto CHECK (direccion || telefono || numeroFax || email != '')
);
CREATE TABLE clientesRelacionTipos (
    CIF INTEGER		CONSTRAINT REF_clientesCIF REFERENCES clientes (CIF),
    tipo CHAR (20)	CONSTRAINT REF_clientesTipo REFERENCES tiposDeClientes (acronimo) ON UPDATE CASCADE DEFAULT 'NEW' NOT NULL,
    CONSTRAINT PK_clienteTipo PRIMARY KEY (CIF, tipo)
);
CREATE TABLE formasDePagoAutorizadas (
    CIF INTEGER			CONSTRAINT REF_clientesCIF REFERENCES clientes (CIF),
    formaDePago CHAR (20)	CONSTRAINT REF_clientesPago REFERENCES formasDePago (acronimo) ON UPDATE CASCADE NOT NULL,
    CONSTRAINT PK_clientePago PRIMARY KEY (CIF, formaDePago)
);
CREATE TABLE facturas (
    id SERIAL			CONSTRAINT PK_facturas PRIMARY KEY,
    fecha TIMESTAMP		NOT NULL	DEFAULT CURRENT_TIMESTAMP,
    cliente INTEGER		CONSTRAINT REF_facturaCliente REFERENCES clientes (CIF)	NOT NULL,
    formaDePago CHAR (20)	CONSTRAINT REF_facturaPago REFERENCES formasDePago (acronimo) ON UPDATE CASCADE NOT NULL,
    CONSTRAINT FK_formaDePago FOREIGN KEY (cliente, formaDePago) REFERENCES clientesRelacionPago (CIF, formaDePago)
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
    color CHAR (30)		CONSTRAINT REF_productosColor REFERENCES color (nombre)	ON UPDATE CASCADE,
    descripcion VARCHAR(200),
    precio NUMERIC (8,3)	CONSTRAINT CHK_productosPrecio CHECK (precio >= 0)	DEFAULT 0,
    existencias INTEGER		CONSTRAINT CHK_existenciasPos CHECK (existencias >= 0)	DEFAULT 0 NOT NULL,
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
	VALUES  ('VISA',	'Tarjeta de crédito VISA'),
		('MC',		'Tarjeta de crédito MasterCard'),
		('DOM',		'Domiciliación bancaria'),
		('TRANS',	'Transferencia bancaria'),
	    	('CHEQ',	'Cheque'),
	    	('EFECT',	'En efectivo / metálico');

INSERT INTO tiposDeClientes (acronimo, descripcion)
	VALUES  ('NEW',		'Nuevo cliente, sin información'),
	    	('GRAN',	'Cliente que mueve más del 10% del capital'),
	    	('PEQ',		'Cliente que mueve más del 1% del capital'),
	    	('MIN',		'Cliente que no mueve mucho capital'),
	    	('VIP',		'Cliente con servicio premium contratado'),
		('PRIOR',	'Cliente con preferencia'),
	    	('CERCA',	'Cliente que vive cerca de la empresa');

INSERT INTO provincias (acronimo, descripcion)
	VALUES  ('BUR', 'Burgos'),
	    	('MAD', 'Madrid'),
	    	('BAR', 'Barcelona');

INSERT INTO ciudades (nombre, provincia)
	VALUES  ('Burgos', 'BUR'),
	    	('Poza de la Sal', 'BUR'),
	    	('Las Rozas', 'MAD');

INSERT INTO clientes (CIF, nombre, direccion, telefono, numeroFax, email, numeroCuenta, formaDePagoDef, ciudad, privincia)
	VALUES  (	49812,
			'Hierros Pepe',
			'Calle Victoria 1234, 2º C',
			NULL,
			NULL,
			'pepe@hpepe.bur',
			123456,
			'TRANS',
			'Burgos',
			'BUR'
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
			'MAD'
		),
		(	3,
			'Maicresof',
			'Calle calle',
			'987654321',
			'987654320',
			'xXmaicresofXx69@hotmeal.es',
			1337,
			'VISA',
			'Poza de la Sal',
			'BUR'
		);

INSERT INTO clientesRelacionTipos (CIF, tipo)
	VALUES	(111,	'GRAN'),
	    	(111,	'PRIOR'),
	    	(49812,	'VIP'),
	    	(49812,	'PEQ'),
	    	(49812,	'CERCA');

INSERT INTO clientesRelacionPago (CIF, formaDePago)
	VALUES 	(49812,	'DOM'),
	    	(49812,	'VISA'),
	    	(111,	'TRANS'),
	    	(111,	'DOM'),
	    	(111,	'MC'),
	    	(3,	'TRANS');

INSERT INTO facturas (fecha, cliente, formaDePago)
	VALUES  (CURRENT_TIMESTAMP,				111,	'TRANS'),
	    	(CURRENT_TIMESTAMP - INTERVAL '16 days',	111,	'TRANS'),
	    	(CURRENT_TIMESTAMP,				49812,	'DOM'),
	    	(CURRENT_TIMESTAMP,				49812,	'DOM'),
	    	(CURRENT_TIMESTAMP - INTERVAL '25 months',	3,	'TRANS');

INSERT INTO color (nombre, r, g, b)
	VALUES  ('Rojo',	255,	0,	0),
	    	('Azul Marino', 28,	107,	160),
	    	('Hierba',	0,	123,	12);

INSERT INTO productos (familia, referencia, color, descripcion, precio, existencias)
	VALUES 	('Mesas',	121314,	'Rojo',		'Mesa estilo moderno de color rojo',	101.01,	300),
	    	('Mesas',	121314,	'Azul Marino',	'Mesa estilo moderno de color azul',	105.5,	200),
	    	('Sillas',	9876,	'Hierba',	'Silla sin patas ni reposa-espaldas',	5.995,	13);

INSERT INTO lineasDeFactura (numeroFactura, productoFamilia, productoReferencia, productoColor, cantidad, precio)
	VALUES  (1,	'Sillas',	9876,	'Hierba',	12,	42.333),
	    	(2,	'Mesas',	121314,	'Rojo',		142,	120),
	    	(2,	'Mesas',	121314,	'Azul Marino',	142,	120),
	    	(5,	'Mesas',	121314,	'Rojo',		987,	99.999),
	    	(5,	'Mesas',	121314,	'Azul Marino',	654,	110.4),
	    	(5,	'Sillas',	9876,	'Hierba',	321,	6);

-- 1:
SELECT nombre, formaDePagoDef FROM (
    SELECT clientes.* FROM clientes, clientesRelacionPago EXCEPT (
    	SELECT clientes.* FROM clientes
	    INNER JOIN clientesRelacionPago ON clientes.CIF = clientesRelacionPago.CIF
	    WHERE formaDePago = formaDePagoDef)) AS clientesConPagoPorDefectoErroneo;
--  2:
SELECT clienteLineaProducto.*, color.r, color.g, color.b FROM (
    SELECT clienteLineaFactura.*, productos.familia, productos.referencia, productos.descripcion, productos.precio AS precioActual FROM (
	SELECT lineasDeFactura.*, clienteInfo.nombre, clienteInfo.direccion FROM (
		SELECT factura.id, clientes.nombre, clientes.direccion FROM (
		    SELECT * FROM facturas WHERE id = 5) AS factura
		    	INNER JOIN clientes ON factura.cliente = clientes.CIF) AS clienteInfo
		INNER JOIN lineasDeFactura ON clienteInfo.id = lineasDeFactura.numeroFactura) AS clienteLineaFactura
	INNER JOIN productos ON clienteLineaFactura.productoReferencia = productos.referencia AND
				clienteLineaFactura.productoColor = productos.color AND
				clienteLineaFactura.productoFamilia = productos.familia) AS clienteLineaProducto
INNER JOIN color ON clienteLineaProducto.productoColor = color.nombre;
-- 3:
SELECT formasDePago.*, COALESCE(TO_CHAR(clienteSel.CIF, 'FM9999999'), 'no usada') AS cliente
	FROM formasDePago LEFT OUTER JOIN
	    (SELECT CIF, formaDePagoDef FROM clientes) as clienteSel
	ON clienteSel.formaDePagoDef = formasDePago.acronimo;
-- 4:
SELECT formasDePago.*, COALESCE(TO_CHAR(clienteSel.CIF, 'FM9999999'), 'no autorizada') AS cliente
	FROM formasDePago LEFT OUTER JOIN
	    (SELECT CIF, formaDePago FROM clientesRelacionPago) as clienteSel
	ON clienteSel.formaDePago = formasDePago.acronimo
ORDER BY acronimo, descripcion, cliente;
