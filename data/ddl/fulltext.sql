
DROP TABLE IF EXISTS dimcand_fulltext;
CREATE TABLE dimcand_fulltext AS
  SELECT cand_sk,
         NULL::tsvector AS fulltxt
  FROM   dimcand;

WITH cnd AS (
  SELECT c.cand_sk,
         setweight(to_tsvector(string_agg(coalesce(p.cand_nm, ''), ' ')), 'A') ||
         setweight(to_tsvector(string_agg(coalesce(p.cand_id, ''), ' ')), 'A') ||
         setweight(to_tsvector(string_agg(coalesce(p.cand_city, ''), ' ')), 'B  ') ||
         setweight(to_tsvector(string_agg(coalesce(p.cand_st, ''), ' ')), 'A') ||
         setweight(to_tsvector(string_agg(coalesce(o.office_tp_desc, ''), ' ')), 'A')
         AS weights
  FROM   dimcand c
  JOIN   dimcandproperties p ON (c.cand_sk = p.cand_sk)
  JOIN   dimcandoffice co ON (co.cand_sk = c.cand_sk)
  JOIN   dimoffice o ON (co.office_sk = o.office_sk)
  GROUP BY c.cand_sk)
UPDATE dimcand_fulltext
SET    fulltxt = (SELECT weights FROM cnd
                  WHERE  dimcand_fulltext.cand_sk = cnd.cand_sk);

CREATE INDEX cand_fts_idx ON dimcand_fulltext USING gin(fulltxt);

DROP TABLE IF EXISTS dimcmte_fulltext;
CREATE TABLE dimcmte_fulltext AS
  SELECT cmte_sk,
         NULL::tsvector AS fulltxt
  FROM   dimcmte;

WITH cmte AS (
  SELECT c.cmte_sk,
         setweight(to_tsvector(string_agg(coalesce(p.cmte_nm, ''), ' ')), 'A') ||
         setweight(to_tsvector(string_agg(coalesce(p.cmte_id, ''), ' ')), 'A') ||
         setweight(to_tsvector(string_agg(coalesce(p.cmte_city, ''), ' ')), 'B') ||
         setweight(to_tsvector(string_agg(coalesce(p.cmte_st, ''), ' ')), 'B') ||
         setweight(to_tsvector(string_agg(coalesce(p.cmte_st_desc, ''), ' ')), 'B') ||
         setweight(to_tsvector(string_agg(coalesce(p.cmte_web_url, ''), ' ')), 'B')
         AS weights
  FROM   dimcmte c
  JOIN   dimcmteproperties p ON (c.cmte_sk = p.cmte_sk)
  GROUP BY c.cmte_sk)
UPDATE dimcmte_fulltext
SET    fulltxt = (SELECT weights FROM cmte
                  WHERE  dimcmte_fulltext.cmte_sk = cmte.cmte_sk);

CREATE INDEX cmte_fts_idx ON dimcmte_fulltext USING gin(fulltxt);

GRANT SELECT ON dimcmte_fulltext TO webro;
GRANT SELECT ON dimcand_fulltext TO webro;


DROP TABLE IF EXISTS name_search_fulltext;
CREATE TABLE name_search_fulltext AS
SELECT DISTINCT
       p.cand_nm AS name,
       to_tsvector(p.cand_nm) as name_vec,
       c.cand_id,
       NULL::text AS cmte_id,
       o.office_tp AS office_sought
FROM   dimcand c
JOIN   dimcandproperties p ON (p.cand_sk = c.cand_sk)
JOIN   dimcandoffice co ON (co.cand_sk = c.cand_sk)
JOIN   dimoffice o ON (co.office_sk = o.office_sk);


INSERT INTO name_search_fulltext
SELECT DISTINCT
       p.cmte_nm AS name,
       to_tsvector(p.cmte_nm) AS name_vec,
       NULL AS cand_id,
       c.cmte_id,
       NULL AS office_sought
FROM   dimcmte c
JOIN   dimcmteproperties p ON (c.cmte_sk = p.cmte_sk);

CREATE INDEX name_search_fts_idx ON name_search_fulltext USING gin(name_vec);
GRANT SELECT ON name_search_fulltext TO webro;

