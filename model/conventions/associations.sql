

CREATE OR REPLACE FUNCTION options_for(relname text, preset text, structure jsonb) RETURNS jsonb language plpgsql AS $$ declare
  options jsonb := '{}';
BEGIN
    IF preset != 'edit' and preset != 'new'   THEN 
      return '{}'::jsonb;
    END IF;

    WITH cols as (select
      value->>'name' as name,
      value
    from jsonb_array_elements(structure))

    SELECT
      jsonb_object_agg(cols.name,
      case when position('_ids' in cols.name) > 0 THEN
        jsonb_from(replace(cols.name, '_ids', ''))
      when position('_id' in cols.name) > 0 THEN
        jsonb_from(inflection_pluralize(replace(cols.name, '_id', '')))
      end)
      FROM cols 
      WHERE cols.name != 'root_id'
      INTO options;

    return options;
END $$;



--SELECT *, o.jsonb_agg as orders, p.jsonb_agg as other
--  FROM orders 
--
--  LEFT JOIN (SELECT items.id, jsonb_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) o 
--  ON o.id = orders.id
--
--  LEFT JOIN (SELECT items.id, jsonb_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) p 
--  ON p.id = orders.id;




-- select possible parents
CREATE OR REPLACE FUNCTION jsonb_from(relname text)
  RETURNS jsonb AS
$BODY$DECLARE
 ret jsonb;
 inputstring text;
BEGIN

  EXECUTE 'SELECT jsonb_agg(r) FROM ( SELECT * FROM '|| quote_ident(relname || '_current') || ') r'
  INTO ret;
  RETURN ret  ;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
