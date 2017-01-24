

-- hack json to convert {"a": [1, 2]} to postgres-friendly {"a": "{1,2}"}
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


CREATE OR REPLACE FUNCTION insert_nested_object(name text, input jsonb)
RETURNS jsonb language plpgsql as $ff$DECLARE
 ret jsonb;
 columns text;
 BEGIN

  IF input->>'content_type' is not null AND input->>'blob_index' is not null THEN
    SELECT input into ret;
  ELSE

    SELECT
      string_agg(key::text, ', ')
      FROM jsonb_each(input)
      WHERE key::text != 'id'
      into columns;

    -- insert nested document
    EXECUTE   'WITH r AS (
                INSERT INTO ' || name || '(' || columns || ') 
                       SELECT ' || columns || ' 
                         FROM json_populate_record(null::'||name||', $1) 
                RETURNING *) 
              SELECT row_to_json(r) FROM r' USING input  
    INTO ret;

  END IF;

  RETURN ret  ;
END;$ff$;
CREATE OR REPLACE FUNCTION insert_nested_objects(name text, input jsonb)
RETURNS jsonb language sql as $ff$
  SELECT jsonb_agg(insert_nested_object(name, value)) 
  FROM jsonb_array_elements(input)
$ff$;

CREATE OR REPLACE FUNCTION process_nested_attributes(input jsonb)
  RETURNS jsonb language sql AS $ff$ 
    SELECT jsonb_object_agg(key, 
     (CASE WHEN jsonb_typeof(value) = 'array' THEN
        insert_nested_objects(key::text, value)
      WHEN jsonb_typeof(value) = 'object' THEN
        insert_nested_object(key::text, value)
      ELSE
        value
      END))
    FROM jsonb_each(input)

$ff$;
