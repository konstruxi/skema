
-- CREATE OR REPLACE FUNCTION xmlarray(input xml[])
-- returns xml AS $BODY$
-- BEGIN
--   return array_to_string(input, '')::xml;
-- END
-- $BODY$
-- LANGUAGE plpgsql VOLATILE;
    

-- Convert XML array into a single xml island and rebase urls 
CREATE OR REPLACE FUNCTION xmlarray(input xml[], linkPath text default '', prefix text default '')
returns xml AS $BODY$
BEGIN
  IF linkPath = '' and prefix = '' THEN
    return array_to_string(input, '')::xml;
  END IF;
  return  regexp_replace(
            array_to_string(input, ''),
            '(src|href)="\.(/)?([^"]*)"',
            '\1="' || prefix || './' || 
              (CASE WHEN linkPath != '' THEN
                trim(linkPath, '/') || '\2'
              ELSE
                ''
              END) || '\3"',
            'gi'
          );
END
$BODY$
LANGUAGE plpgsql VOLATILE;
    

-- Convert xml content into valid xml root with article on top
CREATE OR REPLACE FUNCTION xmlarticleroot(input xml, resource text DEFAULT '', slug text DEFAULT '', column_name text DEFAULT '')
returns xml AS $BODY$
BEGIN
  return xmlelement(
    name article,
    xmlarray(Array(
      select kx_process_section_xml(xml, row_number() OVER(), 
            case when resource = 'services' then
              ''
            else
              slug
            end, 
            column_name)
      from (
        SELECT unnest(sections) as xml
        FROM xpath('//section', xmlelement(name article, 
              input
            )) sections
      ) c
    ))
  );
END
$BODY$
LANGUAGE plpgsql VOLATILE;    

CREATE OR REPLACE FUNCTION kx_process_section_xml(input xml, index bigint, url text, column_name text)
returns xml AS $BODY$
BEGIN

  return xmlelement(
    name section,
    xmlattributes(
      (xpath('@class', input))[1]::text as class,
      -- pattern & index are editor-specific attributes
      (xpath('@pattern', input))[1]::text as pattern,
      (xpath('@index', input))[1]::text as index,
      (xpath('@order', input))[1]::text as order,

      'chapters' as itemprop,
      'chapter' as itemtype,
     

      index as itemindex
    ),
    xmlarray((
      SELECT array_agg(
        CASE WHEN tag = 'h1' and index = 1 and column_name = 'content' THEN
          kx_replace_link_xml(xml, tag, '.')
        WHEN tag = 'h2' and index = 1 and column_name = 'content' THEN
          kx_replace_link_xml(xml, tag, '.')
        WHEN tag = 'h1'
          or tag = 'h2'
          or tag = 'h3' -- todo clean nested elements
          or tag = 'p'
          or tag = 'ul'
          or tag = 'li'
          or tag = 'blockquote'
          or tag = 'picture'
          or tag = 'x-div'
          or tag = 'a' THEN
          kx_localize_link_xml(xml)
        END
      )

      from (
        SELECT 
          (xpath('name()', unnest(i)))[1]::text as tag,
          unnest(i) as xml
        FROM xpath('/section/*', input) i
      ) q
    ), url)
  );
END
$BODY$
LANGUAGE plpgsql VOLATILE;                        


CREATE OR REPLACE FUNCTION xmlarticletext(input xml)
returns xml AS $BODY$
BEGIN
  return array_to_string(xpath('//section', input), '');
END
$BODY$
LANGUAGE plpgsql VOLATILE;                        


CREATE OR REPLACE FUNCTION kx_replace_link_xml(input xml, tag text, url text)
returns xml AS $BODY$
BEGIN
  IF input::text ~ '<a[^>]+>.*</a>' THEN
    return regexp_replace(input::text, '<a[^>]+>(.*)</a>', '<a class="permalink" href="' || url || '">\1</a>')::xml;
  ELSE
    return regexp_replace(input::text, '(<' || tag || '[^>]*>)(.*)(</' || tag || '>)', '\1<a class="permalink" href="' || url || '">\2</a>\3')::xml;
  END IF;
END
$BODY$
LANGUAGE plpgsql VOLATILE;  



-- keep only filenames in references to attached files
CREATE OR REPLACE FUNCTION kx_localize_link_xml(input xml)
returns xml AS $BODY$
BEGIN
  return regexp_replace(input::text, '(href|src)="\./[^"]*?([^/"]+)"', '\1="./\2"', 'g')::xml;
END
$BODY$
LANGUAGE plpgsql VOLATILE;  


-- CREATE OR REPLACE FUNCTION kx_prepend_permalink_url(input xml, url text, prefix text DEFAULT '')
-- returns xml AS $BODY$
-- BEGIN
--   return (
--     regexp_replace(
--       input::text,
--       '(<a class="permalink" href=")([^"]+)',
--       '\1/' || coalesce(prefix, '') || url || '\2'
--     )
--   )::xml
-- ;
-- END
-- $BODY$
-- LANGUAGE plpgsql VOLATILE;  


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
