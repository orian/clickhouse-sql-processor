SELECT
    `ch`.`id` as i,
    toDate(timestamp) as dat,
    col0+17 as c0
FROM clickhouse as ch
    JOIN postgres as pg ON ch.id=pg.id
WHERE
    ch.timestamp > '2025.02.12 15:32'
  AND timestamp < '2025.02.13 01:12'