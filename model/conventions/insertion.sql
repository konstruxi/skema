
CREATE OR REPLACE FUNCTION convert_arrays(input json)
  RETURNS json language sql AS $ff$ 
    SELECT concat('{', string_agg(to_json("key") || ':' || 
           (CASE WHEN value::text ~ '^\[[^\]\{\}]+\]$' THEN
                -- convert arrays to psql array strings
                regexp_replace(
                  -- remove newlines
                  regexp_replace(
                    -- escape double quotes to adhere json syntax
                    regexp_replace(value::text,
                      '"', '\\"', 'g'),
                   '\n', ' ', 'g'),
                '^\[([^\]]+)\]$', '"{\1}"')
            ELSE
              value::text
            END)
      , ','), '}')::json
    FROM json_each(input)

$ff$;


CREATE OR REPLACE FUNCTION insert_nested_object(name text, input json)
RETURNS json language plpgsql as $ff$DECLARE
 ret json;
 columns text;
 BEGIN

  SELECT
    string_agg(key::text, ', ')
    FROM json_each(input)
    WHERE key::text != 'id'
    into columns;

  EXECUTE 'WITH r AS (INSERT INTO ' || name || '(' || columns || ') SELECT ' || columns || ' FROM json_populate_record(null::'||name||', $1) RETURNING *) SELECT row_to_json(r) FROM r' USING input  
  INTO ret;
  RETURN ret  ;
END;$ff$;

CREATE OR REPLACE FUNCTION insert_nested_objects(name text, input json)
RETURNS json language sql as $ff$
  SELECT json_agg(insert_nested_object(name, value)) FROM json_array_elements(input)
$ff$;

CREATE OR REPLACE FUNCTION process_nested_attributes(input json)
  RETURNS json language sql AS $ff$ 
    SELECT concat('{', string_agg(to_json("key") || ':' || 
      (CASE WHEN value::text ~ '^\[[\s\n]*\{.*\}[\s\n]*\]$' THEN
          insert_nested_objects(key::text, value)::text
        ELSE
          value::text
        END)
      , ','), '}')::json
    FROM json_each(input)

$ff$;