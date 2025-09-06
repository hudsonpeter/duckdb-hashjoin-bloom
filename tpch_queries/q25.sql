-- q25.sql: Large multi-table join for stress testing Bloom filter

SELECT
    c.c_name AS customer,
    c.c_mktsegment,
    o.o_orderdate,
    s.s_name AS supplier,
    n.n_name AS nation,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    part p ON l.l_partkey = p.p_partkey
JOIN
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
WHERE
    c.c_mktsegment = 'AUTOMOBILE'
    AND o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    AND p.p_type LIKE '%COPPER'
    AND l.l_returnflag = 'R'
GROUP BY
    c.c_name, c.c_mktsegment, o.o_orderdate, s.s_name, n.n_name;
-- ORDER BY
--     revenue DESC
-- LIMIT 100;
