-- compute jsonb array of tables that reference other table 
-- TODO: Store FK to avoid querying for it elsewhere
CREATE OR REPLACE VIEW structures_and_references AS
SELECT 
    q.*, 
    x.refs as references
FROM structures q

LEFT JOIN(
  SELECT structures.table_name, jsonb_agg(y) as refs
  FROM structures
  INNER JOIN structures y
  ON (EXISTS(SELECT value FROM jsonb_array_elements(y.columns) 
             WHERE value->>'relation_name' = structures.table_name))
  GROUP BY structures.table_name
) x ON (x.table_name = q.table_name);

