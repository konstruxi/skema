-- compute jsonb array of tables that reference other table 
CREATE OR REPLACE VIEW kx_resources_and_references AS
SELECT 
    q.*, 
    x.refs as references
FROM kx_resources q

LEFT JOIN(
  SELECT kx_resources.table_name, jsonb_agg(y) as refs
  FROM kx_resources
  INNER JOIN kx_resources y
  ON (EXISTS(SELECT value FROM jsonb_array_elements(y.columns) 
             WHERE value->>'relation_name' = kx_resources.table_name))
  GROUP BY kx_resources.table_name
) x ON (x.table_name = q.table_name);

