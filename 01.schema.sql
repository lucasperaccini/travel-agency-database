DROP DATABASE IF EXISTS agencia_viajes; -- solo para entorno local de practica
CREATE DATABASE agencia_viajes;
USE agencia_viajes;

-- ======================================================
-- TABLAS PRINCIPALES
-- ======================================================

-- PROVINCIA
CREATE TABLE provincia (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- LUGAR (relacionado con provincia)
CREATE TABLE lugar (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    provincia_id INT NOT NULL,
    FOREIGN KEY (provincia_id) REFERENCES provincia(id)
);

-- USUARIO
CREATE TABLE usuario (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    correo_electronico VARCHAR(100) NOT NULL UNIQUE,
    -- Guardar SOLO el hash (bcrypt/Argon2) generado por la aplicacion, nunca la contraseña en texto plano
    contrasena VARCHAR(255) NOT NULL
);

-- PERSONA (pasajeros o viajeros)
CREATE TABLE persona (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    documento VARCHAR(50),
    fecha_nacimiento DATE,
    telefono VARCHAR(50),
    email VARCHAR(100)
);

-- MEDIO DE PAGO
CREATE TABLE medio_pago (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL
);

-- MEDIO DE TRANSPORTE
CREATE TABLE medio_transporte (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo VARCHAR(50) NOT NULL
);

-- TIPO DE SERVICIO
CREATE TABLE tipo_servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

-- SERVICIO
CREATE TABLE servicio (
    id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_servicio_id INT NOT NULL,
    lugar_origen_id INT NOT NULL,
    lugar_destino_id INT NOT NULL,
    medio_transporte_id INT NOT NULL,
    fecha_salida DATETIME NOT NULL,
    fecha_llegada DATETIME NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    descripcion VARCHAR(200),
    FOREIGN KEY (tipo_servicio_id) REFERENCES tipo_servicio(id),
    FOREIGN KEY (lugar_origen_id) REFERENCES lugar(id),
    FOREIGN KEY (lugar_destino_id) REFERENCES lugar(id),
    FOREIGN KEY (medio_transporte_id) REFERENCES medio_transporte(id)
);

-- RESERVA
CREATE TABLE reserva (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT NOT NULL,
    fecha_hora DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    importe_total DECIMAL(10,2),
    medio_pago_id INT NOT NULL,
    FOREIGN KEY (usuario_id) REFERENCES usuario(id),
    FOREIGN KEY (medio_pago_id) REFERENCES medio_pago(id)
);

-- TABLA INTERMEDIA: reserva_servicio_persona
CREATE TABLE reserva_servicio_persona (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reserva_id INT NOT NULL,
    servicio_id INT NOT NULL,
    persona_id INT NOT NULL,
    observacion VARCHAR(200),
    FOREIGN KEY (reserva_id) REFERENCES reserva(id),
    FOREIGN KEY (servicio_id) REFERENCES servicio(id),
    FOREIGN KEY (persona_id) REFERENCES persona(id)
);


-- INSERTS

-- PROVINCIAS
INSERT INTO provincia (nombre)
VALUES 
('Buenos Aires'), ('Cordoba'), ('Santa Fe'), ('Mendoza'), 
('San Juan'), ('San Luis'), ('Salta'), ('Jujuy'),
('Tucuman'), ('Catamarca'), ('Santiago del Estero'), ('Chaco'),
('Corrientes'), ('Misiones'), ('Entre Rios'), ('Neuquen'),
('Rio Negro'), ('Chubut'), ('Tierra del Fuego');


-- LUGARES
INSERT INTO lugar (nombre, provincia_id)
VALUES
('CABA', 1),
('Mar del Plata', 1),
('La Plata', 1),
('Cordoba', 2),
('Villa Carlos Paz', 2),
('Rosario', 3),
('Santa Fe', 3),
('Mendoza', 4),
('San Rafael', 4),
('San Juan', 5),
('San Luis', 6),
('Salta', 7),
('Cafayate', 7),
('Jujuy', 8),
('Tilcara', 8),
('Tucuman', 9),
('Tafi del Valle', 9),
('Catamarca', 10),
('Santiago del Estero', 11),
('Resistencia', 12),
('Corrientes', 13),
('Posadas', 14),
('Puerto Iguazu', 14),
('Parana', 15),
('Gualeguaychu', 15),
('Neuquen', 16),
('San Martin de los Andes', 16),
('Bariloche', 17),
('Trelew', 18),
('Ushuaia', 19);


-- USUARIOS
INSERT INTO usuario (nombre, apellido, correo_electronico, contrasena)
VALUES
('Juan', 'Perez', 'juan.perez@email.com', 'juan123'),
('Maria', 'Gomez', 'maria.gomez@email.com', 'maria123'),
('Pedro', 'Lopez', 'pedro.lopez@email.com', 'pedro123');

-- PERSONAS
INSERT INTO persona (nombre, apellido, documento, fecha_nacimiento, telefono, email)
VALUES
('Juan', 'Perez', '12345678', '1980-01-01', '1122334455', 'juan.perez@email.com'),
('Maria', 'Gomez', '23456789', '1990-02-15', '2211445566', 'maria.gomez@email.com'),
('Carlos', 'Lopez', '34567890', '1985-05-10', '3344556677', 'carlos.lopez@email.com'),
('Lucia', 'Fernandez', '45678901', '2012-03-12', '4455667788', 'lucia.fernandez@email.com');

-- MEDIOS DE PAGO
INSERT INTO medio_pago (tipo)
VALUES ('billetera_virtual'), ('transferencia'), ('tarjeta_credito'), ('tarjeta_debito');

-- MEDIOS DE TRANSPORTE
INSERT INTO medio_transporte (tipo)
VALUES ('bus'), ('avion'), ('tren'), ('barco');

-- TIPOS DE SERVICIO
INSERT INTO tipo_servicio (nombre)
VALUES ('excursion'), ('traslado');

-- SERVICIOS
INSERT INTO servicio (tipo_servicio_id, lugar_origen_id, lugar_destino_id, medio_transporte_id, fecha_salida, fecha_llegada, precio, descripcion)
VALUES
(1, 1, 8, 2, '2025-11-01 09:00:00', '2025-11-01 18:00:00', 15000.00, 'Excursion a Mendoza'),
(2, 1, 4, 1, '2025-11-05 08:00:00', '2025-11-05 14:00:00', 7000.00, 'Traslado Buenos Aires a Cordoba'),
(1, 4, 12, 2, '2025-12-10 07:00:00', '2025-12-10 16:00:00', 18000.00, 'Excursion a Salta');

-- RESERVAS
INSERT INTO reserva (usuario_id, fecha_hora, importe_total, medio_pago_id)
VALUES
(1, '2025-10-01 10:00:00', 15000.00, 3),
(2, '2025-10-05 12:00:00', 7000.00, 1),
(3, '2025-10-10 15:00:00', 18000.00, 4);

-- RELACION RESERVA-SERVICIO-PERSONA
INSERT INTO reserva_servicio_persona (reserva_id, servicio_id, persona_id, observacion)
VALUES
(1, 1, 1, 'Excursion familiar'),
(1, 2, 3, 'Traslado para Carlos'),
(2, 2, 2, 'Viaje individual'),
(3, 3, 4, 'Excursion con menor');
