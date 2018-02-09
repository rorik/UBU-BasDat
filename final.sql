/*	Trabajo Individual - Bases de Datos UBU
 *	Alumnos:
 *		- Rodrigo Díaz García
 */

DROP TABLE IF EXISTS
    usuarios,
    usuarios_emails,
    usuarios_invitaciones,
    usuarios_documentos,
    usuarios_soporte,
    soporte,
    soporte_emails,
    carteras,
    bloques,
    trabajos,
    transacciones,
    pools,
    pools_trabajo,
    pools_colaboraciones
CASCADE;

/* * * * * * * *
 * Funciones
 * * * * * * * */

CREATE OR REPLACE FUNCTION es_hexadecimal(numero CHAR) RETURNS BOOLEAN AS $$ BEGIN
	RETURN TRIM(numero) ~ '^([\da-fA-F])[\da-fA-F]*$';
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION es_email(email CHAR (40)) RETURNS BOOLEAN AS $$ BEGIN
	RETURN email ~ '[a-zA-Z\d][\w\.\-&%]+[a-zA-Z\d]@[a-zA-Z\d][a-zA-Z\d\-]+[a-zA-Z\d](\.[a-zA-Z]{2,})+';
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION es_email_no_usado(email CHAR (40)) RETURNS BOOLEAN AS $$ BEGIN
	RETURN (SELECT COUNT(*) FROM usuarios_emails WHERE usuarios_emails.email = email) +
	       (SELECT COUNT(*) FROM soporte_emails WHERE soporte_emails.email = email) = 0;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION longitud_cadena(bloque CHAR (16)) RETURNS INTEGER AS $$ DECLARE
	padre CHAR (24) = (SELECT padre FROM bloques WHERE id = bloque);
BEGIN
    	RETURN CASE
	    WHEN bloque IS NULL THEN 0
	    WHEN padre IS NULL THEN 1
	    ELSE longitud_cadena(padre) + 1
	END;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION valor_cadena(bloque CHAR (16)) RETURNS NUMERIC (16, 8) AS $$ BEGIN
	RETURN 1 / (ln(longitud_cadena(bloque)) + 3);
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generar_hexadecimal(tamano INTEGER) RETURNS VARCHAR AS $$ BEGIN
    	IF tamano > 32 THEN
    		RETURN substring(MD5(random()::text) FROM 1 FOR tamano) || generar_hexadecimal(tamano - 32);
	ELSE
    		RETURN substring(MD5(random()::text) FROM 1 FOR tamano);
	END IF;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generar_trabajo(id_padre CHAR (16), descripcion VARCHAR (64)) RETURNS CHAR (24) AS $$ DECLARE
    	codigo_hash CHAR (24);
    	valor_padre NUMERIC (16, 8);
    	valor NUMERIC (16, 8);
    	dificultad_padre NUMERIC (16, 8);
    	dificultad NUMERIC (16, 8);
BEGIN
    	valor_padre = (SELECT trabajos.valor FROM trabajos WHERE hash = (SELECT prueba_trabajo FROM bloques WHERE id = id_padre));
    	dificultad_padre = (SELECT trabajos.dificultad FROM trabajos WHERE hash = (SELECT prueba_trabajo FROM bloques WHERE id = id_padre));
	valor = (pi() - random() + random()) * valor_cadena(id_padre) * valor_padre;
    	dificultad = round(dificultad_padre * (random() / 8 + 1));
    	codigo_hash = generar_hexadecimal(24);
    	INSERT INTO trabajos (hash, descripcion, valor, dificultad) VALUES (codigo_hash, descripcion, valor, dificultad);
    	RETURN codigo_hash;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION actualizar_trabajo() RETURNS trigger AS $$ BEGIN
    	IF NEW.padre != '__UNASSIGNED__' THEN
		NEW.prueba_trabajo = generar_trabajo(NEW.padre, 'Trabajo generado automáticamente');
	END IF;
    	RETURN NEW;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generar_transaccion_id(bloque_id CHAR (16)) RETURNS CHAR (24) AS $$ DECLARE
    	transaccion_id CHAR(24);
BEGIN
    	LOOP
	    transaccion_id = generar_hexadecimal(24);
	    EXIT WHEN (SELECT COUNT(*) FROM transacciones WHERE id = transaccion_id AND bloque = bloque_id) = 0;
	END LOOP;
    	RETURN transaccion_id;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION descubrir_trabajo(trabajo_hash CHAR (24), pool_nombre VARCHAR(64)) RETURNS CHAR (16) AS $$ DECLARE
    	bloque_antiguo CHAR (16);
    	bloque_nuevo CHAR (16);
    	pago_unitario NUMERIC (16, 8);
BEGIN
    	IF (SELECT COUNT(usuario) FROM pools_colaboraciones WHERE trabajo = trabajo_hash AND pool = pool_nombre AND cantidad > 0) = 0 THEN
	    RETURN NULL;
	END IF;
    	bloque_antiguo = (SELECT id FROM bloques WHERE prueba_trabajo = trabajo_hash);
	pago_unitario = (SELECT valor/dificultad FROM trabajos WHERE trabajos.hash = trabajo_hash);
	LOOP
	    bloque_nuevo = generar_hexadecimal(16);
	    EXIT WHEN (SELECT COUNT(*) FROM bloques WHERE id = bloque_nuevo) = 0;
	END LOOP;
    	UPDATE pools_trabajo SET fecha_finalizacion = current_timestamp WHERE trabajo = trabajo_hash AND pool = pool_nombre;
    	INSERT INTO bloques (id, padre, fecha) VALUES (bloque_nuevo, bloque_antiguo, current_timestamp);
	INSERT INTO transacciones (id, bloque, cantidad, esTransferencia, destino, origen_generacion)
	    (SELECT
	     	generar_transaccion_id(bloque_antiguo),
		bloque_antiguo,
		(SELECT pago_unitario * cantidad AS pago
		 FROM pools_colaboraciones
		 WHERE trabajo = trabajo_hash AND pool = pool_nombre AND usuario = colaboracion.usuario),
		FALSE,
		cartera,
		pool_nombre
	    FROM pools_colaboraciones AS colaboracion WHERE trabajo = trabajo_hash AND pool = pool_nombre AND cantidad > 0);
    	UPDATE pools_trabajo SET fecha_finalizacion = now() WHERE trabajo = trabajo_hash;
    	INSERT INTO pools_trabajo
	    (SELECT pool, (SELECT prueba_trabajo FROM bloques WHERE id = bloque_nuevo)
	       FROM pools_trabajo WHERE trabajo = trabajo_hash);

    	RETURN bloque_nuevo;
END $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION realizar_transferencia(bloque_id CHAR (16), cantidad NUMERIC (16, 8), destino CHAR (24), origen CHAR (24)) RETURNS CHAR (24) AS $$ DECLARE
    	transaccion_id CHAR(24);
BEGIN
    	IF cantidad > 0 AND cantidad <= (SELECT total FROM carteras_saldo WHERE id = origen) THEN
	    transaccion_id = generar_transaccion_id(bloque_id);
	    INSERT INTO transacciones (id, bloque, cantidad, esTransferencia, destino, origen_transferencia) VALUES
		(transaccion_id, bloque_id, cantidad, TRUE, destino, origen);
	    RETURN transaccion_id;
	ELSE RETURN NULL;
	END IF;
END $$ LANGUAGE plpgsql;

/* * * * * * * *
 * Tablas
 * * * * * * * */

CREATE TABLE soporte (
    numero_contrato CHAR (10)
	PRIMARY KEY
	CONSTRAINT CHK_contrato CHECK (numero_contrato ~ '\d{8}[A-Z]'),
    nombre CHAR (30)
	NOT NULL
);

CREATE TABLE soporte_emails (
    miembro CHAR (10)
	CONSTRAINT REF_miembro REFERENCES soporte (numero_contrato),
    email CHAR (40)
	NOT NULL
	CONSTRAINT CHK_email CHECK (es_email(email)),
    CONSTRAINT PK_soporte_emails PRIMARY KEY (miembro, email)
);

CREATE TABLE usuarios (
    id CHAR (32)
	PRIMARY KEY
	CONSTRAINT CHK_id CHECK (es_hexadecimal(id))
);

CREATE TABLE usuarios_invitaciones (
    usuario_origen CHAR (32)
	NOT NULL
	CONSTRAINT REF_origen REFERENCES usuarios(id),
    email_destino CHAR (40)
	NOT NULL
	CONSTRAINT CHK_email CHECK (es_email(email_destino)),
    usuario_creado CHAR (32)
	CONSTRAINT UNQ_destino UNIQUE
	CONSTRAINT REF_destino REFERENCES usuarios(id)
        CONSTRAINT CHK_difUsuarios CHECK (usuario_origen != usuario_creado),
    CONSTRAINT PK_invitaciones PRIMARY KEY (usuario_origen, email_destino),
    CONSTRAINT CHK_emailNuevo CHECK (es_email_no_usado(email_destino))
);

CREATE TABLE usuarios_emails (
    usuario CHAR (32)
	CONSTRAINT REF_usuario REFERENCES usuarios (id),
    email CHAR (40)
	NOT NULL
	CONSTRAINT CHK_email CHECK (es_email(email))
	CONSTRAINT UNQ_email UNIQUE,
    CONSTRAINT PK_usuarios_emails PRIMARY KEY (usuario, email)
);

CREATE TABLE usuarios_documentos (
    usuario CHAR (32)
	PRIMARY KEY
    	CONSTRAINT REF_usuario REFERENCES usuarios (id),
    pais VARCHAR (24)
    	NOT NULL,
    valor VARCHAR (32)
    	NOT NULL,
    tipo VARCHAR (32)
    	NOT NULL,
    caducidad DATE
    	NOT NULL
    	CONSTRAINT CHK_caducado CHECK (caducidad > now()),
    CONSTRAINT UNQ_documento UNIQUE (pais, valor, tipo)
);

CREATE TABLE usuarios_soporte (
    usuario CHAR (32)
	PRIMARY KEY
    	CONSTRAINT REF_usuario REFERENCES usuarios (id),
    miembro_soporte CHAR (10)
	CONSTRAINT REF_miembro REFERENCES soporte (numero_contrato)
    	CONSTRAINT UNQ_soporte UNIQUE
);

CREATE TABLE carteras (
    id CHAR (32)
	PRIMARY KEY
	CONSTRAINT CHK_id CHECK (es_hexadecimal(id)),
    propietario CHAR (32)
    	CONSTRAINT REF_usuario REFERENCES usuarios (id)
);

CREATE TABLE trabajos (
    hash CHAR (24)
	PRIMARY KEY
	CONSTRAINT CHK_hash CHECK (es_hexadecimal(trabajos.hash)),
    descripcion VARCHAR (64),
    valor NUMERIC (16, 8)
	NOT NULL
    	CONSTRAINT CHK_valor CHECK (valor > 0),
    dificultad INTEGER
	NOT NULL
    	CONSTRAINT CHK_dificultad CHECK (dificultad > 0)
);

CREATE TABLE bloques (
    id CHAR (16)
	PRIMARY KEY
	CONSTRAINT CHK_id CHECK (es_hexadecimal(id)),
    padre CHAR (16)
	CONSTRAINT REF_padre REFERENCES bloques(id),
    fecha TIMESTAMP
	NOT NULL
	DEFAULT current_timestamp,
    prueba_trabajo CHAR (24)
	NOT NULL
	DEFAULT '__UNASSIGNED__'
	CONSTRAINT CHK_trabajo CHECK (prueba_trabajo = '__UNASSIGNED__' OR es_hexadecimal(prueba_trabajo))
    	CONSTRAINT REF_trabajo REFERENCES trabajos (hash)
);

CREATE TABLE pools (
    nombre VARCHAR(20)
    	PRIMARY KEY
);

CREATE TABLE transacciones (
    id CHAR (24)
	CONSTRAINT CHK_id CHECK (es_hexadecimal(id)),
    bloque CHAR (16)
	CONSTRAINT CHK_bloque CHECK (es_hexadecimal(bloque)),
    cantidad NUMERIC (16, 8)
    	CONSTRAINT CHK_cantidad CHECK (cantidad > 0),
    fecha TIMESTAMP
	NOT NULL
	DEFAULT current_timestamp,
    esTransferencia BOOLEAN
    	NOT NULL,
    destino CHAR (32)
    	NOT NULL
    	CONSTRAINT REF_destino REFERENCES carteras (id),
    origen_transferencia CHAR (32)
	DEFAULT NULL
    	CONSTRAINT REF_transferencia REFERENCES carteras (id),
    origen_generacion CHAR (32)
	DEFAULT NULL
    	CONSTRAINT REF_generacion REFERENCES pools (nombre),
    CONSTRAINT PK_transacciones PRIMARY KEY (id, bloque),
    CONSTRAINT CHK_generacion CHECK (NOT (NOT esTransferencia AND origen_generacion IS NULL)),
    CONSTRAINT CHK_transferencia CHECK (NOT (esTransferencia AND origen_transferencia IS NULL))
);

CREATE VIEW carteras_saldo AS
    SELECT *, entrante - saliente AS total FROM (
	(SELECT carteras.id,
	    coalesce(SUM(entrantes.cantidad), 0) As entrante
	FROM carteras LEFT OUTER JOIN transacciones As entrantes ON carteras.id = entrantes.destino
	GROUP BY (carteras.id)) AS entrantes NATURAL JOIN
	(SELECT carteras.id,
	    coalesce(SUM(salientes.cantidad), 0) AS saliente
	FROM carteras LEFT OUTER JOIN transacciones As salientes ON carteras.id = salientes.origen_transferencia
	GROUP BY (carteras.id)) AS salientes
    ) AS saldo;

CREATE TABLE pools_trabajo (
    pool VARCHAR(20)
    	CONSTRAINT REF_pool REFERENCES pools (nombre),
    trabajo CHAR (24)
    	CONSTRAINT REF_trabajo REFERENCES trabajos (hash),
    fecha_comienzo TIMESTAMP
	NOT NULL
	DEFAULT current_timestamp,
    fecha_finalizacion TIMESTAMP
	DEFAULT NULL,
    CONSTRAINT PK_pools_trabajo PRIMARY KEY (pool, trabajo),
    CONSTRAINT CHK_fecha CHECK (fecha_finalizacion IS NULL OR extract(EPOCH FROM (fecha_finalizacion - pools_trabajo.fecha_comienzo)) > 0)
);

CREATE TABLE pools_colaboraciones (
    pool VARCHAR(20),
    trabajo CHAR (24),
    usuario CHAR (32)
    	CONSTRAINT REF_usuario REFERENCES usuarios (id),
    cartera CHAR (32)
    	NOT NULL
    	CONSTRAINT REF_destino REFERENCES carteras (id),
    cantidad INTEGER
	NOT NULL
	DEFAULT 0
	CONSTRAINT CHK_cantidad CHECK (cantidad >= 0),
    CONSTRAINT PK_colaboraciones PRIMARY KEY (pool, trabajo, usuario),
    CONSTRAINT REF_colaboraciones FOREIGN KEY (pool, trabajo) REFERENCES pools_trabajo (pool, trabajo)
);

CREATE VIEW pool_trabajo_generado AS
    SELECT nombre, trabajo, coalesce(SUM(cantidad), 0) AS total
    	FROM pools
	LEFT OUTER JOIN pools_trabajo ON nombre = pool
	LEFT OUTER JOIN bloques ON trabajo = prueba_trabajo
	LEFT OUTER JOIN transacciones ON nombre = origen_generacion AND bloques.id = bloque
	GROUP BY nombre, trabajo;

CREATE VIEW pool_generado AS
    SELECT nombre, coalesce(SUM(cantidad), 0) AS total
    	FROM pools
	LEFT OUTER JOIN pools_trabajo ON nombre = pool
	LEFT OUTER JOIN bloques ON trabajo = prueba_trabajo
	LEFT OUTER JOIN transacciones ON nombre = origen_generacion AND bloques.id = bloque
	GROUP BY nombre;

/* * * * * * * *
 * Triggers
 * * * * * * * */

CREATE TRIGGER bloque_trabajo
BEFORE INSERT ON bloques
FOR EACH ROW
EXECUTE PROCEDURE actualizar_trabajo();

/* * * * * * * *
 * Queries
 * * * * * * * */

INSERT INTO trabajos (hash, descripcion, valor, dificultad) VALUES ('00000000', 'ZERO', 500, 500);
INSERT INTO bloques (id, padre, fecha, prueba_trabajo) VALUES ('B0', NULL, current_timestamp, '00000000');

INSERT INTO soporte (numero_contrato, nombre) VALUES
    ('48465615O', 'Bob'),
    ('58117658D', 'Alice'),
    ('83641885Z', 'David'),
    ('18102542P', 'Carlos');

INSERT INTO usuarios (id) VALUES (0), (1), (2), (3);

INSERT INTO usuarios_documentos (usuario, pais, valor, tipo, caducidad) VALUES
    (0, 'USA', '2312432', 'Driving License', DATE '2021-12-05'),
    (2, 'España', '12345678A', 'DNI', DATE '2018-03-11'),
    (3, 'España', '549863429812VA', 'Pasaporte', DATE '2026-10-24');

INSERT INTO usuarios_soporte (usuario, miembro_soporte) VALUES
    ('0', '48465615O'),
    ('3', '18102542P');

INSERT INTO carteras (id, propietario) VALUES
    (0, 0),
    (1, 0),
    (2, 0),
    (10, 1),
    (20, 2);
INSERT INTO pools (nombre) VALUES
    ('Uno'),
    ('Zwai'),
    ('San'),
    ('Fire');
INSERT INTO pools_trabajo (pool, trabajo) VALUES
    ('Zwai', '00000000'),
    ('Uno', '00000000'),
    ('Fire', '00000000');
INSERT INTO pools_colaboraciones (pool, trabajo, usuario, cartera, cantidad) VALUES
    ('Zwai', '00000000', 0, 1, 100),
    ('Zwai', '00000000', 1, 10, 400),
    ('Uno', '00000000', 2, 20, 300),
    ('Fire', '00000000', 0, 1, 3),
    ('Fire', '00000000', 1, 2, 30),
    ('Fire', '00000000', 2, 20, 33);

DO $$ BEGIN
    	PERFORM descubrir_trabajo('00000000', 'Zwai');
    	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 20, '10', '1');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 123.456, '20', '10');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 146.544, '20', '10');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 0, '20', '10');
END $$ LANGUAGE plpgsql;
DO $$ BEGIN
    	PERFORM descubrir_trabajo('00000000', 'Uno');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 3.333, '0', '10');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), 3.333, '0', '10');
END $$ LANGUAGE plpgsql;
DO $$ BEGIN
    	PERFORM descubrir_trabajo('00000000', 'Fire');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), pi()::NUMERIC(16, 8), '20', '1');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), pi()::NUMERIC(16, 8), '10', '1');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), pi()::NUMERIC(16, 8), '0', '1');
	PERFORM realizar_transferencia((SELECT id FROM bloques ORDER BY fecha DESC LIMIT 1), pi()::NUMERIC(16, 8), '0', '1');
END $$ LANGUAGE plpgsql;

SELECT pg_sleep(0.2); -- Sincronización con los perform anteriores
SELECT * FROM transacciones;
SELECT * FROM bloques JOIN trabajos ON prueba_trabajo = hash;

/* * * * * * * *
 * Consultas
 * * * * * * * */

/*
 * 1: Una consulta que implique el anidamiento de funciones de agregación.
 *
 * Obtiene la(s) pool(s) con mayor media de generación por trabajo.
 */

WITH medias AS (
    SELECT nombre, AVG(total) AS media
	 FROM pool_trabajo_generado
	 GROUP BY nombre)
SELECT nombre, maximo
    FROM (
	SELECT MAX(media) AS maximo
	FROM medias
    ) AS maximos
    NATURAL JOIN medias
    WHERE media = maximo;

/*
 * 2: Una consulta que sea un cociente mediante subconsulta en el HAVING.
 *
 * Todos los usuarios que tienen más de 100 entre todas sus carteras.
 */

SELECT usuarios.id AS usuario, SUM(total) AS disponible
    FROM usuarios
    JOIN carteras ON usuarios.id = propietario
    JOIN carteras_saldo ON carteras.id = carteras_saldo.id
    GROUP BY usuario
    HAVING SUM(total) > 100;

/*
 * 3: Una resta que necesite joins.
 *
 * Todos los bloques hijos directos del bloque cero que tengan más de 2 transacciones
 */

SELECT bloques.*, COUNT(*)
    FROM bloques
    JOIN transacciones ON bloques.id = transacciones.bloque
    WHERE padre = 'B0'
    GROUP BY bloques.id
    INTERSECT
	SELECT bloques.*, COUNT(*)
	    FROM bloques
	    JOIN transacciones ON bloques.id = transacciones.bloque
	    GROUP BY bloques.id
	    HAVING COUNT(*) > 2;

/*
 * 4: Una intersección que necesite joins.
 *
 * Todos las carteras que no han sacado dinero
 */

SELECT *
    FROM carteras
    EXCEPT
	SELECT carteras.*
	    FROM carteras
	    JOIN transacciones ON carteras.id = transacciones.origen_transferencia;

/*
 * 5: Un join externo con agrupamientos.
 *
 * Todos los usuarios con las pools en las que han participado
 */

SELECT * FROM usuarios
    LEFT OUTER JOIN pools_colaboraciones ON usuarios.id = pools_colaboraciones.usuario;

/*
 * 6: Una subconsulta en el WHERE que no sea representable de forma sencilla mediante joins.
 *
 * Todas las carteras con dinero que hayan movido menos que la media.
 */

WITH cartera AS (
    SELECT carteras.id, carteras_saldo.entrante, carteras_saldo.saliente, carteras_saldo.total
    	FROM carteras
	LEFT JOIN carteras_saldo ON carteras_saldo.id = carteras.id)
SELECT cartera.*, (SELECT AVG(subcartera.saliente) FROM cartera AS subcartera WHERE subcartera.total > 0) AS media
    FROM cartera
    WHERE saliente < (SELECT AVG(subcartera.saliente) FROM cartera AS subcartera WHERE subcartera.total > 0)
