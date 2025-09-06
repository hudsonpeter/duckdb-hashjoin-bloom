-- q23.sql: Simple join between orders and customer using correct TPC-H column names

SELECT
    o.o_orderkey,
    o.o_orderdate,
    c.c_name AS customer_name,
    c.c_mktsegment
FROM
    orders o
JOIN
    customer c
    ON o.o_custkey = c.c_custkey
WHERE
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    AND c.c_mktsegment = 'BUILDING';
-- ORDER BY
--     o.o_orderdate;
