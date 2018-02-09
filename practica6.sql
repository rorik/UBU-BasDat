/*	Práctica 6 - Bases de Datos UBU
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
    formasDePagoAutorizadas,
    comerciales,
    contactos
CASCADE;


CREATE TABLE formasDePago (
    acronimo CHAR (20)	CONSTRAINT PK_formasDePago PRIMARY KEY,
    descripcion CHAR (100)
);
CREATE TABLE comerciales (
    DNI CHAR (10)	PRIMARY KEY	CONSTRAINT CHK_comercialDNI CHECK (UPPER(DNI) ~ '[A-HJ-NP-SU-Z\d]\d{7}[A-Z]'),
    nombre CHAR (30)	NOT NULL,
    ape1 CHAR (30)	NOT NULL,
    ape2 CHAR (30)	NOT NULL,
    tfno CHAR (20)	CONSTRAINT CHK_comercialTlf CHECK (tfno IS NULL OR TRIM(tfno) ~
		'(\+\d{1,3}\-)?[679]\d{2}(\-?\d{3}){2}(#\d{1,4})?'),
    e_mail CHAR (40)	CONSTRAINT CHK_comercialEmail CHECK (e_mail IS NULL OR e_mail ~
		'[a-zA-Z\d][\w\.\-&%]+[a-zA-Z\d]@[a-zA-Z\d][a-zA-Z\d\-]+[a-zA-Z\d](\.[a-zA-Z]{2,})+'),
    CONSTRAINT CHK_metodoContacto CHECK (tfno || e_mail != '')
    /*
    	Dependencias Funcionales:
    	    FD1: DNI -> nombre
    	    FD2: DNI -> ape1
    	    FD3: DNI -> ape2
    	    FD4: DNI -> tfno
    	    FD5: DNI -> e_mail
    	Claves Candidatas:
    	    DNI es el único atributo que no puede ser derivado de otro, por lo tanto:
    	    CK1: DNI
	Super Clave:
	    DNI		(CK1)
    	Forma Normal:
    	    Está en BCNF ya que para cada dependencia A -> B, A es una super clave (DNI).
    	    También es 2NF porque ningún atributo no primario depende de una parte de ninguna clave candidata.
    	    Es 3NF ya que está en 2NF y ningún atributo no primario se encuentra de manera transitiva en ninguna CK.
     */
);
CREATE TABLE tiposDeClientes (
    acronimo CHAR (20)		CONSTRAINT PK_tiposDeClientes PRIMARY KEY,
    responsable CHAR (10)	CONSTRAINT REF_comercialesDNI REFERENCES comerciales (DNI)
    				CONSTRAINT UNQ_responsable UNIQUE	NOT NULL,
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
    telefono CHAR (20)		CONSTRAINT CHK_clienteTlf CHECK (telefono IS NULL OR TRIM(telefono) ~
		'(\+\d{1,3}\-)?[679]\d{2}(\-?\d{3}){2}(#\d{1,4})?'),
    numeroFax CHAR (20)		CONSTRAINT CHK_clienteFax CHECK (numeroFax IS NULL OR TRIM(numeroFax) ~
		'(\+\d{1,3}\-)?[679]\d{2}(\-?\d{3}){2}(#\d{1,4})?'),
    email CHAR (30)		CONSTRAINT CHK_clienteEmail CHECK (email IS NULL OR email ~
		'[a-zA-Z\d][\w\.\-&%]+[a-zA-Z\d]@[a-zA-Z\d][a-zA-Z\d\-]+[a-zA-Z\d](\.[a-zA-Z]{2,})+'),
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
    CONSTRAINT FK_formaDePago FOREIGN KEY (cliente, formaDePago) REFERENCES formasDePagoAutorizadas (CIF, formaDePago)
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
CREATE TABLE contactos (
    comercial CHAR (10)	CONSTRAINT REF_comercialesDNI REFERENCES comerciales (DNI),
    cliente INTEGER	CONSTRAINT REF_clientesCIF REFERENCES clientes (CIF),
    fecha DATE,
    CONSTRAINT PK_contactos PRIMARY KEY (comercial, cliente, fecha)
    /*
    	Dependencias Funcionales:
    	    FD1: comercial	-> comercial	(TRIVIAL)
    	    FD2: cliente	-> cliente	(TRIVIAL)
    	    FD3: fecha		-> fecha	(TRIVIAL)
    	Claves Candidatas:
    	    Podemos observar que comercial no se encuentra en la parte derecha de ninguna dependencia funcional que
    	    no sea trivial. Por lo tanto comercial debe estar en todas las claves. Lo mismo ocurre con cliente y fecha.
    	    CK1: comercial, cliente, fecha
	Super Clave:
	    comercial, cliente, fecha	(CK1)
    	Forma Normal:
    	    No está en BCNF porque en una de las dependencias A -> B, A no es una super clave (FD1, FD2, FD3).
	    Si está en 2NF ya que ningún atributo no primario depende de alguna parte de una clave.
	    Si está en 3NF porque todas las dependencias son triviales.
     */
);

INSERT INTO formasDePago (acronimo, descripcion)
	VALUES  ('VISA',	'Tarjeta de crédito VISA'),
		('MC',		'Tarjeta de crédito MasterCard'),
		('DOM',		'Domiciliación bancaria'),
		('TRANS',	'Transferencia bancaria'),
	    	('CHEQ',	'Cheque'),
	    	('EFECT',	'En efectivo / metálico');

INSERT INTO comerciales (DNI,	nombre,	ape1,		ape2,		tfno,			e_mail)
	VALUES	('12345678A',	'Juan',	'del Barco',	'Gómez',	'666222555',		'juan@correo.ses'),
	    	('X0000254J',	'Ana',	'Heras',	'López',	'+34-947123123#22',	'gasda@weebs.co.uk'),
	    	('K5555555K',	'Van',	'Darkholme',	'Ta-Da-Shi',	'+46-777666555',	'hejdopappa@an3le.se');

INSERT INTO tiposDeClientes (acronimo, responsable, descripcion)
	VALUES  ('NEW',		'12345678A',	'Nuevo cliente, sin información'),
	    	('MEDIO',	'X0000254J',	'Medio'),
	    	('GRANDE',	'K5555555K',	'Clientes con más de 2000 empleados');

INSERT INTO provincias (acronimo, descripcion)
	VALUES  ('BUR', 'Burgos'),
	    	('MAD', 'Madrid'),
	    	('BAR', 'Barcelona');

INSERT INTO ciudades (nombre, provincia)
	VALUES  ('Burgos', 'BUR'),
	    	('Poza de la Sal', 'BUR'),
	    	('Las Rozas', 'MAD'),
	    	('Majadahonda', 'MAD');

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
			'923456789',
			'923456789#22',
			'ventas@amazonas.amz',
			10,
			'TRANS',
			'Las Rozas',
			'MAD'
		),
		(	3,
			'Maicresof',
			'C/ Principal 2, Escalera 1, Puerta 7B',
			'987654321',
			'987654320',
			'xXmaicresofXx69@hotmeal.es',
			1337,
			'VISA',
			'Poza de la Sal',
			'BUR'
		);

INSERT INTO clientesRelacionTipos (CIF, tipo)
	VALUES	(111,	'NEW'),
	    	(49812,	'NEW'),
	    	(49812,	'MEDIO'),
	    	(49812,	'GRANDE'),
	    	(3,	'MEDIO'),
	    	(111,	'GRANDE');

INSERT INTO formasDePagoAutorizadas (CIF, formaDePago)
	VALUES 	(49812,	'DOM'),
	    	(49812,	'VISA'),
	    	(111,	'TRANS'),
	    	(111,	'DOM'),
	    	(111,	'MC'),
	    	(3,	'TRANS');

INSERT INTO facturas (fecha, cliente, formaDePago)
	VALUES  (CURRENT_TIMESTAMP,	111,	'TRANS'),
	    	(DATE '2012-12-12',	111,	'TRANS'),
	    	(DATE '2013-07-22',	49812,	'DOM'),
	    	(DATE '2012-11-10',	49812,	'DOM'),
	    	(DATE '2012-01-01',	3,	'TRANS');

INSERT INTO color (nombre, r, g, b)
	VALUES  ('Rojo',	255,	0,	0),
	    	('Azul Marino', 28,	107,	160),
	    	('Hierba',	0,	123,	12),
	    	('Blanco Nube',	237,	237,	237);

INSERT INTO productos (familia, referencia, color, descripcion, precio, existencias)
	VALUES 	('Mesas',	121314,	'Rojo',		'Mesa estilo moderno de color rojo',	101.01,	300),
	    	('Mesas',	121314,	'Azul Marino',	'Mesa estilo moderno de color azul',	105.5,	200),
	    	('Sillas',	9876,	'Hierba',	'Silla sin patas ni reposa-espaldas',	5.995,	13),
	    	('Lamparas',	5,	'Blanco Nube',	'Lámpara de techo con lineas verticales de color blanco nube y fondo negro',	44, 0);

INSERT INTO lineasDeFactura (numeroFactura, productoFamilia, productoReferencia, productoColor, cantidad, precio)
	VALUES  (1,	'Sillas',	9876,	'Hierba',	12,	42.333),
	    	(2,	'Sillas',	9876,	'Hierba',	321,	6),
	    	(3,	'Mesas',	121314,	'Rojo',		142,	120),
	    	(3,	'Mesas',	121314,	'Azul Marino',	142,	120),
	    	(4,	'Mesas',	121314,	'Rojo',		987,	99.999),
	    	(4,	'Mesas',	121314,	'Azul Marino',	654,	110.4),
	    	(4,	'Sillas',	9876,	'Hierba',	321,	6),
	    	(5,	'Mesas',	121314,	'Rojo',		1751,	95),
	    	(5,	'Mesas',	121314,	'Azul Marino',	6880,	92.2);

INSERT INTO contactos (comercial, cliente, fecha)
	VALUES 	('K5555555K', 3, DATE '2014-06-02'),
	    	('K5555555K', 3, DATE '2014-06-03'),
	    	('K5555555K', 111, DATE '2014-06-04'),
	    	('X0000254J', 111, DATE '2014-06-04'),
	    	('X0000254J', 3, DATE '2014-06-04'),
	    	('X0000254J', 3, DATE '2015-05-05'),
	    	('X0000254J', 3, DATE '2016-06-06'),
	    	('X0000254J', 111, DATE '2016-06-07'),
	    	('X0000254J', 49812, DATE '2016-06-07');

-- 1:
/* Comerciales con números de telefono españoles */
SELECT * FROM comerciales WHERE tfno LIKE '+34%' OR tfno NOT LIKE '+%';
/* Productos que tienen el color en la descripción */
SELECT color, descripcion FROM productos WHERE LOWER(descripcion) LIKE '%' || LOWER(color) || '%';
/* Clientes cuya dirección es una calle */
SELECT nombre, direccion FROM clientes WHERE LOWER(direccion) LIKE 'calle%' OR UPPER(direccion) LIKE 'C/%';
/* Comerciales con apellidos compuestos */
SELECT nombre, ape1, ape2 FROM comerciales WHERE
	LOWER(ape1) ~ '^[a-záéíóú]+([-\s][a-záéíóú]+)+$' OR
	LOWER(ape2) ~ '^[a-záéíóú]+([-\s][a-záéíóú]+)+$';
/* Ciudades que empiezan con la misma letra que su provincia */
SELECT nombre AS ciudad, descripcion AS provincia FROM ciudades JOIN provincias ON ciudades.provincia = provincias.acronimo
	WHERE nombre LIKE SUBSTRING(descripcion FROM 1 FOR 1) || '%';


-- 2:
SELECT AVG(precio*cantidad) AS Importe_Medio FROM facturas
	JOIN clientes ON facturas.cliente = clientes.CIF
	JOIN lineasDeFactura ON id = lineasDeFactura.numeroFactura
	WHERE privincia = 'BUR';
-- 3:
SELECT SUM(precio) AS Volumen_Medio_2012 FROM facturas
	JOIN lineasDeFactura ON facturas.id = lineasDeFactura.numeroFactura
	WHERE fecha BETWEEN DATE '2012-01-01' AND DATE '2012-12-31';
-- 4:
SELECT COUNT(*) AS Numero_Visitas_Medio_Grande FROM comerciales
	JOIN contactos		ON comerciales.DNI = contactos.comercial
    	JOIN tiposDeClientes	ON comerciales.DNI = tiposDeClientes.responsable
    	JOIN clientes		ON contactos.cliente = clientes.CIF
    	INNER JOIN clientesRelacionTipos ON clientes.CIF = clientesRelacionTipos.CIF
	WHERE tiposDeClientes.acronimo = 'MEDIO' AND clientesRelacionTipos.tipo = 'GRANDE'
