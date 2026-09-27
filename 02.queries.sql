-- consultas parte 1
# Realizar las siguientes consultas:
# a) Listar los nombres completos y correos de todos los viajeros, en mayúscula.
# b) Mostrar las reservas realizadas en el último mes, indicando fecha, nombre
# completo del viajero, importe total y medio de pago.
# c) Calcular el importe promedio de las reservas, redondeado a 2 decimales.
# d) Listar todos los servicios disponibles, indicando su nombre, tipo y el lugar de
# origen, ordenados por lugar.
# e) Mostrar cuántas reservas tiene cada usuario, ordenadas de mayor a menor
# por cantidad.
# f) Mostrar cuántas reservas tiene cada persona, ordenadas de mayor a menor
# por cantidad.
# g) Mostrar para cada reserva los servicios contratados por persona.
# h) Obtener el total facturado por tipo de medio de pago. Mostrar solo aquellos
# que superen los $5.000.
# i) Listar los usuarios que no hayan hecho ninguna reserva.
# j) Obtener los 5 destinos más reservados, con su cantidad de servicios
# contratados.
# k) Obtener la cantidad total de servicios contratados por cada usuario, junto con
# su total gastado, ordenados por el total gastado en orden descendente.
# l) Mostrar la fecha del último viaje de cada viajero.
# m) Calcular el número de días entre la fecha de reserva y la fecha de salida de
# cada reserva.
# n) Encontrar el medio de pago que más se ha utilizado, junto con el total
# facturado a través de ese medio.
# o) Mostrar los usuarios que han reservado servicios de todos los lugares
# disponibles.
# p) Mostrar los usuarios que han hecho más de una reserva en el mismo día.
# q) Calcular el gasto promedio por usuario.
# r) Mostrar cuántas reservas se hicieron agrupadas por el tipo de servicio.
# s) Mostrar las reservas que contengan viajeros menores de edad.
# t) Mostrar cantidad de reservas por destino y por medio de transporte.

-- ---------------------------------------------------------------- -- 
use agencia_viajes;
 -- 5) a_
 SELECT UPPER(CONCAT(nombre, ' ', apellido)) AS nombre_completo, 
       UPPER(email) AS correo
FROM persona;

-- b_
SELECT r.fecha_hora, 
       CONCAT(p.nombre, ' ', p.apellido) AS viajero,
       r.importe_total, 
       mp.tipo AS medio_pago
FROM reserva r
JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
JOIN persona p ON rsp.persona_id = p.id
JOIN medio_pago mp ON r.medio_pago_id = mp.id
WHERE r.fecha_hora >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH);

-- c_
SELECT ROUND(AVG(importe_total), 2) AS importe_promedio
FROM reserva;

-- d_
SELECT s.descripcion AS servicio, 
       ts.nombre AS tipo_servicio, 
       lo.nombre AS lugar_origen
FROM servicio s
JOIN tipo_servicio ts ON s.tipo_servicio_id = ts.id
JOIN lugar lo ON s.lugar_origen_id = lo.id
ORDER BY lo.nombre;

-- e_
SELECT u.nombre, u.apellido, COUNT(r.id) AS cantidad_reservas
FROM usuario u
LEFT JOIN reserva r ON u.id = r.usuario_id
GROUP BY u.id
ORDER BY cantidad_reservas DESC;

-- f_
SELECT p.nombre, p.apellido, COUNT(DISTINCT rsp.reserva_id) AS cantidad_reservas
FROM persona p
LEFT JOIN reserva_servicio_persona rsp ON p.id = rsp.persona_id
GROUP BY p.id
ORDER BY cantidad_reservas DESC;

-- g_
SELECT r.id AS reserva_id, 
       CONCAT(p.nombre, ' ', p.apellido) AS persona, 
       s.descripcion AS servicio
FROM reserva r
JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
JOIN persona p ON rsp.persona_id = p.id
JOIN servicio s ON rsp.servicio_id = s.id
ORDER BY r.id;

-- h_
SELECT mp.tipo AS medio_pago, SUM(r.importe_total) AS total_facturado
FROM reserva r
JOIN medio_pago mp ON r.medio_pago_id = mp.id
GROUP BY mp.tipo
HAVING total_facturado > 5000;

-- i_
SELECT u.nombre, u.apellido, u.correo_electronico
FROM usuario u
LEFT JOIN reserva r ON u.id = r.usuario_id
WHERE r.id IS NULL;

-- j_
SELECT ld.nombre AS destino, COUNT(rsp.id) AS cantidad_servicios
FROM reserva_servicio_persona rsp
JOIN servicio s ON rsp.servicio_id = s.id
JOIN lugar ld ON s.lugar_destino_id = ld.id
GROUP BY ld.nombre
ORDER BY cantidad_servicios DESC
LIMIT 5;

-- k_
SELECT u.nombre, u.apellido,
       COUNT(rsp.servicio_id) AS total_servicios,
       (SELECT COALESCE(SUM(r2.importe_total), 0)
        FROM reserva r2
        WHERE r2.usuario_id = u.id) AS total_gastado
FROM usuario u
LEFT JOIN reserva r ON u.id = r.usuario_id
LEFT JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
GROUP BY u.id, u.nombre, u.apellido
ORDER BY total_gastado DESC;

-- l_
SELECT p.nombre, p.apellido, MAX(s.fecha_salida) AS ultimo_viaje
FROM persona p
JOIN reserva_servicio_persona rsp ON p.id = rsp.persona_id
JOIN servicio s ON rsp.servicio_id = s.id
GROUP BY p.id;

-- m_ 
SELECT r.id AS reserva_id, 
       DATEDIFF(s.fecha_salida, r.fecha_hora) AS dias_entre_reserva_y_salida
FROM reserva r
JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
JOIN servicio s ON rsp.servicio_id = s.id;

-- n_
SELECT mp.tipo AS medio_pago, COUNT(r.id) AS cantidad_usos, SUM(r.importe_total) AS total_facturado
FROM reserva r
JOIN medio_pago mp ON r.medio_pago_id = mp.id
GROUP BY mp.id
ORDER BY cantidad_usos DESC
LIMIT 1;

-- o_
SELECT u.nombre, u.apellido
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id
JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
JOIN servicio s ON rsp.servicio_id = s.id
GROUP BY u.id
HAVING COUNT(DISTINCT s.lugar_destino_id) = (SELECT COUNT(*) FROM lugar);

-- p_
SELECT u.nombre, u.apellido, DATE(r.fecha_hora) AS fecha, COUNT(*) AS cantidad
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id
GROUP BY u.id, DATE(r.fecha_hora)
HAVING cantidad > 1;

-- q_
SELECT u.nombre, u.apellido, ROUND(AVG(r.importe_total), 2) AS gasto_promedio
FROM usuario u
JOIN reserva r ON u.id = r.usuario_id
GROUP BY u.id;

-- r_ 
SELECT ts.nombre AS tipo_servicio, COUNT(DISTINCT rsp.reserva_id) AS cantidad_reservas
FROM reserva_servicio_persona rsp
JOIN servicio s ON rsp.servicio_id = s.id
JOIN tipo_servicio ts ON s.tipo_servicio_id = ts.id
GROUP BY ts.id;

-- s_
SELECT DISTINCT r.id AS reserva_id, 
       CONCAT(p.nombre, ' ', p.apellido) AS viajero, 
       TIMESTAMPDIFF(YEAR, p.fecha_nacimiento, CURDATE()) AS edad
FROM reserva r
JOIN reserva_servicio_persona rsp ON r.id = rsp.reserva_id
JOIN persona p ON rsp.persona_id = p.id
WHERE TIMESTAMPDIFF(YEAR, p.fecha_nacimiento, CURDATE()) < 18;

-- t_
SELECT ld.nombre AS destino, mt.tipo AS medio_transporte, COUNT(DISTINCT rsp.reserva_id) AS cantidad_reservas
FROM reserva_servicio_persona rsp
JOIN servicio s ON rsp.servicio_id = s.id
JOIN lugar ld ON s.lugar_destino_id = ld.id
JOIN medio_transporte mt ON s.medio_transporte_id = mt.id
GROUP BY ld.nombre, mt.tipo
ORDER BY cantidad_reservas DESC;


