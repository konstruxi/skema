CREATE OR REPLACE FUNCTION compose_sql(relname text, structure jsonb, relations jsonb)
  RETURNS text AS
$BODY$DECLARE
 list_content text;
BEGIN

  -- Compose category.posts_content and category.posts[].content into a single thing

  IF jsonb_typeof(relations) = 'array' THEN
  SELECT string_agg('
    xmlelement(
      name article, 
      xmlattributes(
        ''content'' as class,
        ''' || inflection_singularize(relname) || ''' as itemtype,
        ''' || relname || ''' as itemprop,
        root.root_id as itemid
      ),
    xmlarray(Array(SELECT section FROM (' ||
      -- Pickup content from from `articles_content` XML column of a `category`
      (CASE WHEN EXISTS(SELECT 1 
                           FROM jsonb_array_elements(structure) c 
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

      CASE WHEN relation.value->>'compose_sql' is not NULL THEN
        relation.value->>'compose_sql'
      ELSE
        -- List children documents
        'SELECT 
          xmlelement(
            name section,
            xmlattributes(
              (xpath(''@class'', xpath[1]))[1] as class,
              ''' || inflection_singularize(value->>'table_name') || ''' as itemtype,
              ''' || (value->>'table_name') || ''' as itemprop,
              root.root_id as itemid
            ),
            xmlarray(xpath(''/*/*'', xpath[1])) 
          ) as section, 
          row_number() OVER (ORDER BY id DESC) as index
          
          FROM ' || (value->>'table_name') || '_current, ' 
                 || 'xpath(''//section[1]'', ' || (value->>'table_name') || '_current.content)
          WHERE ' || 
            CASE WHEN EXISTS(SELECT 1 
                             FROM jsonb_array_elements(value->'columns') c 
                             WHERE c->>'name' = relname ||  '_ids') THEN
              'root.root_id = ' || (value->>'table_name') || '_current.' || relname ||  '_ids'
            ELSE
              'root.root_id = ' || (value->>'table_name') || '_current.' || inflection_singularize(relname) ||  '_id'
            END
      END || '
      ORDER BY index DESC
    )
  )))', ', ')
    FROM jsonb_array_elements(relations) relation
    INTO list_content;
  END IF;
   
  RETURN '
    SELECT root.*,
    xmlconcat(xmlelement(
      name article, 
      xmlattributes(''content'' as class),
      xmlarray(xpath(''//section'', root.content))
    ),
      ' || coalesce(list_content, '''''') || '
    ) as xml
    FROM ' || relname || '_current root
    WHERE 1=1
  ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;