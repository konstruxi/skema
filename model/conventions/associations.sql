

CREATE OR REPLACE FUNCTION options_for(relname text, preset text, structure json) RETURNS json language plpgsql AS $$ declare
  options json := '{}';
BEGIN
    IF preset != 'edit' and preset != 'new'   THEN 
      return '{}'::json;
    END IF;

    WITH cols as (select
      value->>'name' as name,
      value
    from json_array_elements(structure))

    SELECT
      json_object_agg(cols.name,
      case when position('_ids' in cols.name) > 0 THEN
        json_from(replace(cols.name, '_ids', '') || '_current')
      when position('_id' in cols.name) > 0 THEN
        json_from(inflection_pluralize(replace(cols.name, '_id', '')) || '_current')
      end)
      FROM cols 
      WHERE cols.name != 'root_id'
      INTO options;

    return options;
END $$;



--SELECT *, o.json_agg as orders, p.json_agg as other
--  FROM orders 
--
--  LEFT JOIN (SELECT items.id, json_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) o 
--  ON o.id = orders.id
--
--  LEFT JOIN (SELECT items.id, json_agg(orders) from items LEFT JOIN orders ON (items.order_id = orders.id) GROUP BY items.id) p 
--  ON p.id = orders.id;




-- select possible parents
CREATE OR REPLACE FUNCTION json_from(relname text)
  RETURNS json AS
$BODY$DECLARE
 ret json;
 inputstring text;
BEGIN

  EXECUTE 'SELECT json_agg(r) FROM ( SELECT * FROM '|| quote_ident(relname || '_current') || ') r'
  INTO ret;
  RETURN ret  ;
END;
$BODY$
LANGUAGE plpgsql VOLATILE;
