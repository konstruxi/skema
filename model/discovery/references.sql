
-- compute json array of tables that reference other table 
CREATE OR REPLACE VIEW structures_and_references AS
SELECT 
    q.*, 
    x.refs as references
FROM structures q

LEFT JOIN(
  SELECT structures.table_name, json_agg(y) as refs
  FROM structures
  INNER JOIN structures y
  ON (EXISTS(SELECT value FROM json_array_elements(y.columns) WHERE 
      value->>'name' =(inflection_singularize(structures.table_name) || '_id') OR
      value->>'name' = structures.table_name || '_ids'))
  GROUP BY structures.table_name
) x ON (x.table_name = q.table_name);

