-- Returns SQL query that selects from specified table with related rows aggregated as jsonb
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
        replace(relation.value->>'compose_sql','root.*,', '')
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
    ) collection
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
    ) as xml,
    0 as index
    FROM ' || relname || '_current root
    WHERE 1=1
  ';
END;
$BODY$
LANGUAGE plpgsql VOLATILE;



CREATE OR REPLACE FUNCTION xmlarray(input xml[])
returns xml AS $BODY$
BEGIN
  return array_to_string(input, '')::xml;
END
$BODY$
LANGUAGE plpgsql VOLATILE;


-- Take 
CREATE OR REPLACE FUNCTION xmlsection(section xml, attributes xml)
returns xml AS $BODY$
BEGIN
  return xmlelement(
    name section,
    xmlarray(xpath('/*', section))
  );
END
$BODY$
LANGUAGE plpgsql VOLATILE;        

-- Convert xml content into valid xml root with article on top
CREATE OR REPLACE FUNCTION xmlarticle(input xml)
returns xml AS $BODY$
BEGIN
  return xmlelement(
    name article,
    case when input is document and (xpath('/article', input))[1] is not null then
      xmlarray(xpath('//section', input))
    ELSE
      xmlarray(xpath('//section', xmlelement(name article, input)))
    end
  );
END
$BODY$
LANGUAGE plpgsql VOLATILE;                        




-- Convert xml content into valid xml root with article on top
CREATE OR REPLACE FUNCTION xmlarticle(input text)
returns xml AS $BODY$
BEGIN
  return xmlelement(
    name article,
    case when input is document and (xpath('/article', input))[1] is not null then
      xmlarray(xpath('//section', input))
    ELSE
      xmlarray(xpath('//section', xmlelement(name article, input)))
    end
  );
END
$BODY$
LANGUAGE plpgsql VOLATILE;                        