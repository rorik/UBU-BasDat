/*	Práctica 1 - Bases de Datos UBU
 *	Alumnos:
 *		- Rodrigo Díaz García
 */

DROP TABLE IF EXISTS practica1, practica1usuarios;

/* La siguiente tabla sólo es usada para comprobar referencias */
CREATE TABLE practica1usuarios ( -- tabla de referencia
	usuario VARCHAR(16)	PRIMARY KEY
	--...
);
INSERT INTO practica1usuarios values ('abc'), ('juan_br'), ('alberto'), ('admin'), ('forsen'), ('u1'), ('u2'), ('u3'); -- tabla de referencia
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

CREATE TABLE practica1(-- Registro de logins del servidor
	id INTEGER		CONSTRAINT PK_loginId PRIMARY KEY				CONSTRAINT CHK_loginId CHECK (id >= 0),
	usuario VARCHAR(16)	CONSTRAINT REF_loginUsuario REFERENCES practica1usuarios	NOT NULL,
	hash CHAR(10)		CONSTRAINT CHK_loginHash CHECK (bit_length(hash) = 80)		NOT NULL, -- Encriptación de 80 bits = 10 char
	cookie CHAR(8)		CONSTRAINT UNQ_loginCookie UNIQUE				NOT NULL,
	ip BIT(8)		DEFAULT B'10110010'						NOT NULL, -- Primeros 8 bits de la ip
	delay NUMERIC(6,3)	CONSTRAINT CHK_loginDelay CHECK (delay >= 0)			DEFAULT 0, -- Distancia cliente-servidor en s
	tiempo TIMESTAMP	DEFAULT CURRENT_TIMESTAMP					NOT NULL,
	ultimoLogin TIMESTAMP	DEFAULT TIMESTAMP '2016-12-25 14:57:01'				NOT NULL,
	CONSTRAINT CHK_loginTiempo CHECK (tiempo >= ultimoLogin)
);	/* Podría crearse una restricción de tabla para el tamaño de hash y cookie, si esta última se cambiase a 10 caracteres,
	* o establecer otra restricción similar a CHK_loginHash para un bit_length de 64 en cookie, pero no es necesario.
	* Permitimos que delay pueda ser NULL en caso de error de lectura/no aplicable */

INSERT INTO practica1 values (	1,	'abc',		'3b62667bc7',	'abCdEfGH',	B'10101010',	0.032),
			     (	2,	'juan_br',	'5031744b5f',	'12345678',	B'01110111',	DEFAULT);

INSERT INTO practica1 values (	4,	'alberto',	'5ad02a10aa',	'aaaaaaaa',	DEFAULT,	999.999,	DEFAULT, 		'2005-04-03 02:01:00'),
			     (	99,	'forsen',	'ZULULZULUL',	'OMEGALUL',	DEFAULT,	11+4,		'2074-04-30 21:32:43',	'2015-02-24 17:41:18');

/* Inserts que demuestran los errores producidos por constraints */
--INSERT INTO practica1 values (	2,	'admin',	'005547a752',	'FfFfFfFf',	B'11111111');--error: pk_loginid
--INSERT INTO practica1 values (	-3,	'admin',	'005547a753',	'FfFfFfFe',	B'11111111');--error: chk_loginid
--INSERT INTO practica1 values (	3,	'paco',		'adb6a564c2',	'FfFfFfFd',	B'00110011');--error: ref_loginusuario
--INSERT INTO practica1 values (	47,	'admin',	'3b62667bc7',	'12345678',	B'00000001');--error: unq_logincookie
--INSERT INTO practica1 values (	48,	'admin',	'hash',		'abCdEfG0',	B'00000001');--error: chk_loginhash
--INSERT INTO practica1 values (	49,	'admin',	'005547a754',	'abCdEfG1',	B'00000001', -23.23);--error: chk_logindelay
--INSERT INTO practica1 values (	33,	'admin',	NULL,		'abCdEfG2');--error: hash not null
--INSERT INTO practica1 values (	34,	'admin',	'005547a751',	NULL);--error: cookie not null
--INSERT INTO practica1 values (	35,	'admin',	'005547a752',	'abCdEfG3',	NULL);--error: ip not null
--INSERT INTO practica1 values (	36,	'admin',	'005547a753',	'abCdEfG4',	B'00001111', 1, NULL);--error: tiempo not null
--INSERT INTO practica1 values (	37,	'admin',	'005547a754',	'abCdEfG5',	B'00001111', 2, DEFAULT, NULL);--error: ultimoLogin not null
--INSERT INTO practica1 values (	38,	'admin',	'005547a755',	'abCdEfG6',	DEFAULT, 1, '2012-10-15 23:59:59', '2018-05-25 14:57:01');--error: chk_logintiempo
/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

INSERT INTO practica1 values (	80,	'u1',	'8a4371e9da',	'b5c8b683',	B'00000000',	NULL,	CURRENT_TIMESTAMP,		CURRENT_TIMESTAMP - INTERVAL '2 hours'),
			     (	81,	'u2',	'68945ab802',	'9793c25f',	B'00000001',	1.4995,	'2011-08-08 08:08:08',		'2011-08-08 08:08:08'),
			     (	82,	'u3',	'bd15c2ea17',	'deca5e7c',	B'00000010',	1.4994,	'1492-07-23 12:14:16.171819',	'0001-01-01 00:00:00');

SELECT * FROM practica1;