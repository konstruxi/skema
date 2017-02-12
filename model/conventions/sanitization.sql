
CREATE OR REPLACE FUNCTION xmlarray(input xml[])
returns xml AS $BODY$
BEGIN
  return array_to_string(input, '')::xml;
END
$BODY$
LANGUAGE plpgsql VOLATILE;
    

-- Convert xml content into valid xml root with article on top
CREATE OR REPLACE FUNCTION xmlarticleroot(input xml, resource text, slug text, column_name text)
returns xml AS $BODY$
BEGIN
  return xmlelement(
    name article,
    xmlarray(Array(
      select kx_process_section_xml(xml, row_number() OVER(), '/' || slug, column_name)
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
declare
  itemorder text;
BEGIN
  select unnest(m)
  from regexp_matches(input::text, '<section[^>]+index="(\d+)">') m
  LIMIT 1
  into itemorder;

  return xmlelement(
    name section,
    xmlattributes(
      (xpath('@class', input))[1]::text as class,
      -- pattern & index are editor-specific attributes
      (xpath('@pattern', input))[1]::text as pattern,
      (xpath('@index', input))[1]::text as index,
      'chapters' as itemprop,
      'chapter' as itemtype,
     
      itemorder as order, 

      index as itemindex
    ),
    xmlarray((
      SELECT array_agg(
        CASE WHEN tag = 'h1' and index = 1 and column_name = 'content' THEN
          kx_replace_link_xml(xml, tag, url)
        WHEN tag = 'h2' and index = 1 and column_name = 'content' THEN
          kx_replace_link_xml(xml, tag, url)
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
          xml
        END
      )

      from (
        SELECT 
          (xpath('name()', unnest(i)))[1]::text as tag,
          unnest(i) as xml
        FROM xpath('/section/*', input) i
      ) q
    ))
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


CREATE OR REPLACE FUNCTION kx_prepend_permalink_url(input xml, url text)
returns xml AS $BODY$
BEGIN
  return (
    regexp_replace(
      input::text,
      '(<a class="permalink" href=")([^"]+)',
      '\1/' || url || '\2'
    )
  )::xml
;
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
