

-- compute jsonb array of related tables for each table 
CREATE OR REPLACE VIEW structures_and_children AS
SELECT 
    q.*, 
    s.relations as relations

FROM structures_and_references q

LEFT JOIN (
  SELECT 

    structs.table_name, 
    inflection_pluralize(replace(value->>'name', '_id', '')) as relation,
    row_to_json(x)::jsonb as relations
    
    from structures structs, jsonb_array_elements(structs.columns) as rls
    

  LEFT JOIN (
    SELECT z.table_name, jsonb_agg(z.columns) as columns
    FROM (
      SELECT * FROM structures 
    ) z
    GROUP BY z.table_name
  ) x
  ON (x.table_name = inflection_pluralize(replace(value->>'name', '_id', '')) or 
      x.table_name = replace(value->>'name', '_ids', ''))

  WHERE position('_id' in rls.value->>'name') > 0 
    and rls.value->>'name' != 'root_id'

) s
ON (q.table_name = s.table_name);

-- produce configuration for nested resources
-- by duplicating tables for each relation
CREATE OR REPLACE VIEW structures_hierarchy AS
SELECT 
structures.*,
inflection_pluralize(replace(parent.column_name, '_id', ''))  as parent_name,
inflection_pluralize(replace(grandparent.column_name, '_id', ''))             as grandparent_name,

(SELECT columns 
  from structures q 
  where table_name = inflection_pluralize(replace(parent.column_name, '_id', ''))
  LIMIT 1) as parent_structure, 

(SELECT columns 
  from structures q 
  where table_name = inflection_pluralize(replace(grandparent.column_name, '_id', ''))
  LIMIT 1) as grandparent_structure

FROM structures_and_children structures

LEFT JOIN (
  SELECT column_name, columns.table_name
  from INFORMATION_SCHEMA.COLUMNS columns
  UNION SELECT '', ''
) parent
on ((structures.table_name = parent.table_name
  AND position('_id' in parent.column_name) > 0
  AND position('_ids' in parent.column_name) = 0
  AND parent.column_name != 'root_id')
  or parent.table_name = '' )


LEFT JOIN (
  SELECT column_name, columns.table_name
  from INFORMATION_SCHEMA.COLUMNS columns
  UNION SELECT '', ''
) grandparent
on ((inflection_pluralize(replace(parent.column_name, '_id', '')) = grandparent.table_name
  AND (position('_id' in grandparent.column_name) > 0 
    AND position('_ids' in grandparent.column_name) = 0) 
  AND grandparent.column_name != 'root_id')
  or grandparent.table_name = '');




