USE agencia_viajes;

--  1: VARIABLES
-- 1.a) Definir variable con precio promedio de todos los servicios

SELECT AVG(precio) INTO @precio_promedio_servicios FROM servicio;
SELECT @precio_promedio_servicios AS precio_promedio_servicios;

-- 1.b) Guardar en una variable el total de reservas de un mes dado
--       (ejemplo: mes=10, anio=2025)
SET @mes := 10;
SET @anio := 2025;
SELECT COUNT(*) INTO @total_reservas_mes
FROM reserva
WHERE MONTH(fecha_hora) = @mes AND YEAR(fecha_hora) = @anio;
SELECT @total_reservas_mes AS total_reservas_mes;

-- SECCION 2: FUNCIONES Y PROCEDIMIENTOS
-- 2.a) Funcion total_pasajeros_reserva(reserva_id) 

DELIMITER $$
DROP FUNCTION IF EXISTS total_pasajeros_reserva $$
CREATE FUNCTION total_pasajeros_reserva(p_reserva_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE v_count INT;
    SELECT COUNT(DISTINCT persona_id) INTO v_count
    FROM reserva_servicio_persona
    WHERE reserva_id = p_reserva_id;
    RETURN IFNULL(v_count, 0);
END $$
DELIMITER ;

-- Ejemplo de uso:
SELECT total_pasajeros_reserva(1) AS pasajeros_en_reserva_1;

-- 2.b) Procedimiento que liste todas las reservas de un usuario dado (por correo)
DELIMITER $$
DROP PROCEDURE IF EXISTS listar_reservas_usuario_por_email $$
CREATE PROCEDURE listar_reservas_usuario_por_email(IN p_email VARCHAR(100))
BEGIN
    SELECT r.id AS reserva_id,
           r.fecha_hora,
           r.importe_total,
           mp.tipo AS medio_pago,
           GROUP_CONCAT(DISTINCT CONCAT(p.nombre,' ',p.apellido) SEPARATOR '; ') AS pasajeros
    FROM reserva r
    JOIN usuario u ON u.id = r.usuario_id
    LEFT JOIN medio_pago mp ON mp.id = r.medio_pago_id
    LEFT JOIN reserva_servicio_persona rsp ON rsp.reserva_id = r.id
    LEFT JOIN persona p ON p.id = rsp.persona_id
    WHERE u.correo_electronico = p_email
    GROUP BY r.id, r.fecha_hora, r.importe_total, mp.tipo
    ORDER BY r.fecha_hora;
END $$
DELIMITER ;

-- Ejemplo de invocación:
CALL listar_reservas_usuario_por_email('juan.perez@email.com');

-- 3.a) Procedimiento que verifique si los viajeros de una reserva son mayores de edad,si hay menores, devolver un mensaje indicando el viajero menor

DELIMITER $$
DROP PROCEDURE IF EXISTS verificar_mayoria_pasajeros_reserva $$
CREATE PROCEDURE verificar_mayoria_pasajeros_reserva(IN p_reserva_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_persona_id INT;
    DECLARE v_nombre VARCHAR(100);
    DECLARE v_apellido VARCHAR(100);
    DECLARE v_fecha_nac DATE;
    DECLARE v_edad INT;

    DECLARE cur1 CURSOR FOR
        SELECT DISTINCT p.id, p.nombre, p.apellido, p.fecha_nacimiento
        FROM reserva_servicio_persona rsp
        JOIN persona p ON p.id = rsp.persona_id
        WHERE rsp.reserva_id = p_reserva_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN cur1;
    read_loop: LOOP
        FETCH cur1 INTO v_persona_id, v_nombre, v_apellido, v_fecha_nac;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;

        -- calcular edad 
        SET v_edad = TIMESTAMPDIFF(YEAR, v_fecha_nac, CURDATE());

        IF v_edad < 18 THEN
            SELECT CONCAT('ADVERTENCIA: El viajero ', v_nombre, ' ', v_apellido,
                          ' es menor de edad (', v_edad, ' años) y debe ir acompañado por un mayor.')
                   AS mensaje;
        ELSE
            -- opcional: informar que es mayor
            SELECT CONCAT('OK: ', v_nombre, ' ', v_apellido, ' - edad ', v_edad) AS mensaje;
        END IF;
    END LOOP;
    CLOSE cur1;
END $$
DELIMITER ;

-- Ejemplo:
CALL verificar_mayoria_pasajeros_reserva(3);


-- 4.a) Crear usuario admin_agencia con todos los privilegios sobre la BD
CREATE USER IF NOT EXISTS 'admin_agencia'@'localhost' IDENTIFIED BY 'CAMBIAR_ESTA_CLAVE';
GRANT ALL PRIVILEGES ON agencia_viajes.* TO 'admin_agencia'@'localhost';
FLUSH PRIVILEGES;

-- 4.b) Crear usuario consulta_reservas con permisos solo de lectura sobre reservas y servicios
CREATE USER IF NOT EXISTS 'consulta_reservas'@'localhost' IDENTIFIED BY 'CAMBIAR_ESTA_CLAVE';
GRANT SELECT ON agencia_viajes.reserva TO 'consulta_reservas'@'localhost';
GRANT SELECT ON agencia_viajes.servicio TO 'consulta_reservas'@'localhost';
GRANT SELECT ON agencia_viajes.reserva_servicio_persona TO 'consulta_reservas'@'localhost';
FLUSH PRIVILEGES;

-- 4.c) Revocar permisos de modificacion al usuario consulta_reservas (si existieran)
-- No hace falta revocar: el usuario nunca recibio INSERT/UPDATE/DELETE, solo SELECT (ver 4.b).
-- Ejecutar un REVOKE sobre permisos inexistentes da error ("There is no such grant defined").
-- Se verifica mostrando los permisos actuales:
SHOW GRANTS FOR 'consulta_reservas'@'localhost';

-- 5.a) Crear trigger que registre en tabla auditoria cualquier eliminacion de reservas

-- Tabla de auditoria
DROP TABLE IF EXISTS reserva_auditoria;
CREATE TABLE reserva_auditoria (
    id INT AUTO_INCREMENT PRIMARY KEY,
    reserva_id INT,
    usuario_id INT,
    fecha_hora DATETIME,
    importe_total DECIMAL(10,2),
    medio_pago_id INT,
    eliminado_por VARCHAR(100),
    fecha_eliminacion DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$
DROP TRIGGER IF EXISTS trg_before_delete_reserva $$
CREATE TRIGGER trg_before_delete_reserva
BEFORE DELETE ON reserva
FOR EACH ROW
BEGIN
    -- registrar los valores de la reserva que se está eliminando
    INSERT INTO reserva_auditoria (reserva_id, usuario_id, fecha_hora, importe_total, medio_pago_id, eliminado_por)
    VALUES (OLD.id, OLD.usuario_id, OLD.fecha_hora, OLD.importe_total, OLD.medio_pago_id, CURRENT_USER());
END $$
DELIMITER ;

-- 6.a) Generar lista usando UNION para mostrar:

SELECT 'Listado de usuarios con reservas asociadas' AS line
UNION ALL
SELECT CONCAT(u.nombre, ' ', u.apellido, ' | ', u.correo_electronico) AS line
FROM usuario u
WHERE EXISTS (SELECT 1 FROM reserva r WHERE r.usuario_id = u.id)
UNION ALL
SELECT '------------------------------' AS line
UNION ALL
SELECT 'Listado de usuarios sin reservas asociadas' AS line
UNION ALL
SELECT CONCAT(u.nombre, ' ', u.apellido, ' | ', u.correo_electronico) AS line
FROM usuario u
WHERE NOT EXISTS (SELECT 1 FROM reserva r WHERE r.usuario_id = u.id);


-- 7.a) Crear vista 'recaudacion_total_por_mes' con cantidad total por mes

DROP VIEW IF EXISTS recaudacion_total_por_mes;
CREATE VIEW recaudacion_total_por_mes AS
SELECT YEAR(fecha_hora) AS anio,
       MONTH(fecha_hora) AS mes,
       SUM(importe_total) AS total_recaudado,
       COUNT(*) AS cantidad_reservas
FROM reserva
GROUP BY YEAR(fecha_hora), MONTH(fecha_hora)
ORDER BY anio DESC, mes DESC;

-- Ejemplo de consulta:
SELECT * FROM recaudacion_total_por_mes;
-- 8.a) Obtener nombre del usuario que haya realizado la reserva más costosa
SELECT u.nombre, u.apellido, r.id AS reserva_id, r.importe_total
FROM reserva r
JOIN usuario u ON u.id = r.usuario_id
WHERE r.importe_total = (SELECT MAX(importe_total) FROM reserva)
LIMIT 1;

-- 8.b) Mostrar servicios cuyo precio está por encima del precio promedio
SELECT s.*
FROM servicio s
WHERE s.precio > (SELECT AVG(precio) FROM servicio);

-- 9.a) Procedimiento que elimine una reserva y todos los servicios asociados a ella y eliminar la persona (viajero) si no esta asociada a otras reservas.

DELIMITER $$
DROP PROCEDURE IF EXISTS eliminar_reserva_y_asociados $$
CREATE PROCEDURE eliminar_reserva_y_asociados(IN p_reserva_id INT)
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE v_persona_id INT;

    -- El cursor recorre una tabla temporal, no la tabla que vamos a borrar
    DECLARE cur_personas CURSOR FOR SELECT persona_id FROM tmp_personas;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        DROP TEMPORARY TABLE IF EXISTS tmp_personas;
        SELECT 'ERROR: Se produjo un error. Se hizo ROLLBACK' AS mensaje;
    END;

    -- 1) guardar las personas de la reserva ANTES de borrar nada
    DROP TEMPORARY TABLE IF EXISTS tmp_personas;
    CREATE TEMPORARY TABLE tmp_personas AS
        SELECT DISTINCT persona_id FROM reserva_servicio_persona WHERE reserva_id = p_reserva_id;

    START TRANSACTION;

    -- 2) borrar las filas de relacion
    DELETE FROM reserva_servicio_persona WHERE reserva_id = p_reserva_id;

    -- 3) borrar cada persona que ya no aparezca en otras reservas
    OPEN cur_personas;
    read_loop: LOOP
        FETCH cur_personas INTO v_persona_id;
        IF done = 1 THEN
            LEAVE read_loop;
        END IF;
        IF (SELECT COUNT(*) FROM reserva_servicio_persona WHERE persona_id = v_persona_id) = 0 THEN
            DELETE FROM persona WHERE id = v_persona_id;
        END IF;
    END LOOP;
    CLOSE cur_personas;

    -- 4) borrar la reserva
    DELETE FROM reserva WHERE id = p_reserva_id;

    COMMIT;
    DROP TEMPORARY TABLE IF EXISTS tmp_personas;
    SELECT CONCAT('OK: Reserva ', p_reserva_id, ' y asociados eliminados (si correspondia).') AS mensaje;
END $$
DELIMITER ;

-- Ejemplo:
 CALL eliminar_reserva_y_asociados(2);

-- 10.a) Crear indice unico sobre correo_electronico en tabla usuario
-- Ya existe: la columna se definio como UNIQUE al crear la tabla, y eso genera un indice unico automaticamente.
-- Crear otro seria redundante (ocupa espacio y hace mas lentos los INSERT/UPDATE).
-- Se verifica listando los indices de la tabla:
SHOW INDEX FROM usuario;
-- 10.b) Generar consulta y explicar con EXPLAIN
CREATE FULLTEXT INDEX ft_persona_nombre_apellido ON persona(nombre, apellido);

-- Busqueda usando el indice FULLTEXT:
SELECT nombre, apellido FROM persona WHERE MATCH(nombre, apellido) AGAINST('Perez');

EXPLAIN SELECT nombre, apellido FROM persona WHERE MATCH(nombre, apellido) AGAINST('Perez');
-- Resultado: type = fulltext, key = ft_persona_nombre_apellido
-- MySQL usa el indice para encontrar las filas sin recorrer toda la tabla.

-- Comparacion: la misma busqueda con LIKE no puede usar el indice:
EXPLAIN SELECT nombre, apellido FROM persona WHERE apellido LIKE '%Perez%';
-- Resultado: type = ALL, key = NULL
-- ALL significa que recorre todas las filas (full table scan).
-- Con pocos registros no se nota, pero con millones es mucho mas lento.



