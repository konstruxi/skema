-- Returns SQL query that selects from specified table with related rows aggregated as jsonb
CREATE OR REPLACE FUNCTION compose_sql(relname text, structure jsonb, relations jsonb, tag text default 'article', classname text default 'content')
  RETURNS text AS
$BODY$DECLARE
  id_column text;
  list_content text;
  url_prefix text;
BEGIN
  SELECT (CASE WHEN EXISTS(SELECT 1 
                           FROM jsonb_array_elements(structure) c 
                           WHERE c->>'name' = 'version') THEN
      'root_id'
  ELSE
      'id'
  END) INTO id_column;


  -- Quite an abstraction leak:
  -- Process relative links in nested XML documents and rebase them on top of parent document
  -- Each document/static file should have a single canonical URL within sitemap
  -- But there's a way to reach document through subdomain and main domain:
  -- `username.kx.com/slug/file.jpg` is equal `to kx.con/~username/slug/file.jpg`

  -- Also adds ~username prefix which is a substitute for subdomain name
  SELECT (CASE WHEN relname = 'services' THEN
      ':prefix'
  ELSE
      'concat_ws(''/'', nullif(trim(:prefix, ''/''), ''''), nullif(:slug3, ''''), nullif(:slug2, ''''), root.slug) || ''/'''
  END) INTO url_prefix;


  -- Compose category.articles_content and category.articles[].content into a single thing

  IF jsonb_typeof(relations) = 'array' THEN
  SELECT string_agg('
    xmlelement(
      name div, 
      xmlattributes(
        ''content list'' as class,
        ''' || (value->>'singular') || ''' as itemtype,
        ''' || (value->>'table_name') || ''' as itemtable
      ),
    xmlarray(Array(SELECT xml FROM (' ||
      -- Pickup content from from `articles_content` XML column of a `category`
      (CASE WHEN EXISTS(SELECT 1 
                           FROM jsonb_array_elements(structure) c 
                           WHERE c->>'name' = (relation.value->>'table_name') ||  '_content') THEN
        '
        SELECT
          unnest(xpath) as xml,
          (xpath(''//section/@order'', unnest(xpath)))[1]::varchar::float as index
          FROM xpath(''//section'', root.' || (value->>'table_name') || '_content)

        UNION ALL
        '
      ELSE
        ''
      END) || 

      ' SELECT 
        xmlelement(
          name header,
          xmlelement(
            name a,
            xmlattributes(''./' || (value->>'table_name') || '/'' as href),
            ''' || (value->>'alias') || '''::xml
          )
        ) as xml,
        -1 as index
        UNION ALL
      '
      ||

      CASE WHEN relation.value->>'compose_sql' is not NULL THEN
        replace(relation.value->>'compose_sql','root.*,', '') || ' and service_id = coalesce(nullif(:service_id, '''')::integer, service_id)'
        
      ELSE
        -- List children documents
        'SELECT 
          xmlelement(
            name article,
            xmlattributes(
              concat_ws('' '', ''content'', (xpath(''@class'', xpath[1]))[1]::text) as class,
              ''' || inflection_singularize(value->>'table_name') || ''' as itemtype,
              ''' || (value->>'table_name') || ''' as itemprop,
              ' || (CASE WHEN EXISTS(SELECT 1 
                                   FROM jsonb_array_elements(value->'columns') c 
                                   WHERE c->>'name' = 'version') THEN
                        (value->>'table_name') || '_current.root_id as itemid, '
                    ELSE
                        (value->>'table_name') || '_current.id as itemid, '
                    END)
              || '
              ' || (value->>'table_name') || '_current.slug as itemname
            ),
            xpath[1]
          ) as xml, 
          row_number() OVER (ORDER BY root_id DESC) as index
          
          FROM ' || (value->>'table_name') || '_current, ' 
                 || 'xpath(''//section[1]'', ' || (value->>'table_name') || '_current.content)
          WHERE ' || 
            CASE WHEN EXISTS(SELECT 1 
                             FROM jsonb_array_elements(value->'columns') c 
                             WHERE c->>'name' = relname ||  '_ids') THEN
              'root.' || id_column || ' = ' || (value->>'table_name') || '_current.' || relname ||  '_ids'
            ELSE
              'root.' || id_column || ' = ' || (value->>'table_name') || '_current.' || inflection_singularize(relname) ||  '_id'
            END
      END || '
      ORDER BY index ASC
    ) collection
  ), ' || url_prefix || ', ''/''))', ', ')
    FROM jsonb_array_elements(relations) relation
    INTO list_content;
  END IF;
   
  RETURN '
    SELECT root.*,
    xmlconcat(xmlelement(
      name article, 
      xmlattributes(
        ''content'' as class,
        ''' || inflection_singularize(relname::varchar) || ''' as itemtype,
        ''' || relname || ''' as itemprop,
        root.' || id_column || ' as itemid,
        root.slug as itemname
      ),
      xmlarray(xpath(''//section'', root.content)),
      ' || coalesce(list_content, '''''') || '
    )
    ) as xml,
    row_number() OVER(ORDER BY ' || id_column || ' DESC) as index
    FROM ' || relname || '_current root
    WHERE 1=1
  ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;



