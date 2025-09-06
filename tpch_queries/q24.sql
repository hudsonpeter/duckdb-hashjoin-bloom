-- q24.sql: Multi-way join using correct TPC-H column names

SELECT
    o.o_orderkey,
    o.o_orderdate,
    c.c_name AS customer_name,
    c.c_mktsegment,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM
    orders o
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    AND c.c_mktsegment = 'BUILDING'
    AND l.l_returnflag = 'R'
GROUP BY
    o.o_orderkey, o.o_orderdate, c.c_name, c.c_mktsegment;
-- ORDER BY
--     total_revenue DESC;
