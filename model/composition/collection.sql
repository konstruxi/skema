-- Returns SQL query that selects from specified table with related rows aggregated as json
CREATE OR REPLACE FUNCTION compose_sql(relname text, structure json, relations json)
  RETURNS text AS
$BODY$DECLARE
 list_content text;
BEGIN

  -- Compose category.posts_content and category.posts[].content into a single thing

  IF json_typeof(relations) = 'array' THEN
  SELECT string_agg('
    xmlelement(
      name article, 
      xmlattributes(''content'' as class),
    array_to_string(Array(SELECT section FROM (' ||
      -- Pickup content from from `articles_content` XML column of a `category`
      (CASE WHEN EXISTS(SELECT 1 
                           FROM json_array_elements(structure) c 
                           WHERE c->>'name' = (relation.value->>'table_name') ||  '_content') THEN
        '
        SELECT
          unnest(xpath) as section,
          (xpath(''//section/@order'', unnest(xpath)))[1]::varchar::int as index
          FROM xpath(''//section'', root.' || (value->>'table_name') || '_content)

        UNION ALL
        '
      ELSE
        ''
      END) || 

      -- List children documents
      'SELECT 
        xpath[1] as section, 
        row_number() OVER (ORDER BY id DESC) as index
        
        FROM ' || (value->>'table_name') || ', xpath(''//section[1]'', ' || (value->>'table_name') || '.content)
        WHERE ' || 
          CASE WHEN EXISTS(SELECT 1 
                           FROM json_array_elements(value->'columns') c 
                           WHERE c->>'name' = relname ||  '_ids') THEN
            'root.id = ' || (value->>'table_name') || '.' || relname ||  '_ids'
          ELSE
            'root.id = ' || (value->>'table_name') || '.' || inflection_singularize(relname) ||  '_id'
          END
        || '
      ORDER BY index DESC
    ) collection
  ), '''')::xml)', ', ')
    FROM json_array_elements(relations) relation
    INTO list_content;
  END IF;
   
  RETURN '
    SELECT root.*,
    xmlconcat(xmlelement(
      name article, 
      xmlattributes(''content'' as class),
      array_to_string(xpath(''//section'', root.content), '''')::xml
    ),
      ' || coalesce(list_content, '''''') || '
    ) as xml
    FROM categories_current root
    WHERE 1=1
  ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;


SELECT compose_sql(
  'categories',
  '[{"name": "title"}, {"name": "articles_content"}]'::json,
  '[{"table_name": "articles", "columns": [{"name": "category_id"}]}]'::json
);