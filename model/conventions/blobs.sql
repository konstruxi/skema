-- Assign blob references to the record from a flat array
CREATE OR REPLACE FUNCTION assign_uploaded_blobs(old_blobs bytea[], new_blobs_json jsonb, new_blobs bytea[])
RETURNS bytea[] language plpgsql as $ff$ declare
  final_blobs bytea[];
begin
  IF new_blobs_json::text NOT LIKE '[%' THEN
    SELECT ('[' || new_blobs_json::text || ']')::json 
    into new_blobs_json;
  END IF;

  SELECT ARRAY(
    SELECT new_blobs[(value->>'blob_index')::int + 1]
    FROM jsonb_array_elements(new_blobs_json)
    WHERE value->>'blob_index' is not NULL
  ) into final_blobs;

  return final_blobs;
end; $ff$;


CREATE OR REPLACE FUNCTION initialize_file(file jsonb)
RETURNS jsonb language plpgsql as $ff$ begin
  
  
  IF file->>'name' ~ '\\?' THEN
    return file || 
          -- extract metadata from query string in filename
          (SELECT 
            coalesce(
              jsonb_object_agg(m[1], m[2]), 
              '{}'::jsonb) 
          FROM regexp_matches(file->>'name', E'[\\?&]([a-z_-]+)\=([a-z0-9_-]+)', 'g') as m) ||

          -- cleanup filename
          jsonb_build_object('name', regexp_replace(file->>'name', E'\\?.*', ''));


  END IF;

  return file;

end $ff$;

CREATE OR REPLACE FUNCTION assign_file_indecies(files jsonb)
RETURNS jsonb language plpgsql as $ff$ declare
counter integer:= 0;
i int;
begin

  IF jsonb_typeof(files) = 'object' THEN
    if files->>'blob_index' IS NOT NULL THEN
      return jsonb_set(files, '{index}', to_jsonb(1));
    END IF;
  ELSE
    FOR i IN 0..coalesce(jsonb_array_length(files), 0)
      LOOP
        IF jsonb_extract_path(files, i::text, 'blob_index'::text) IS NOT NULL THEN
          counter:= counter + 1;
          files := jsonb_set(files, ('{' || i || ',index}')::text[], to_jsonb(counter)); 
        END IF;
      END LOOP;
  END IF;

  return files;
end; $ff$;



-- new_files is one or multiple json values. 
--   Objects represent newly uploaded files,
--   string represent filenames of old files to keep
CREATE OR REPLACE FUNCTION assign_file_list(new_files jsonb, old_files jsonb default null)
RETURNS jsonb language plpgsql as $ff$ begin
  return CASE 
          -- recurse for each value in array
          WHEN jsonb_typeof(new_files) = 'array' THEN
            (SELECT jsonb_agg(files.assign_file_list)
                FROM (
                  SELECT assign_file_list(value, old_files)
                  FROM jsonb_array_elements(new_files)
                  WITH ORDINALITY
                ) files
            WHERE files.assign_file_list is not NULL)
          -- a json object - got a new file
          WHEN jsonb_typeof(new_files) = 'object' THEN
            -- ignore objects without blob
            CASE WHEN new_files->>'blob_index' is not NULL THEN
              initialize_file(new_files)
            END
          -- a filename, should inherit file from previous version
          WHEN jsonb_typeof(new_files) = 'string' THEN
            -- find a matching filename in old list
            CASE WHEN jsonb_typeof(old_files) = 'array' THEN
              (SELECT value - 'blob_index' - 'index'
              FROM jsonb_array_elements(old_files)
              WHERE value->'name' = new_files
              LIMIT 1)
            -- check if old file matches name
            WHEN jsonb_typeof(old_files) = 'object' THEN
              CASE WHEN old_files->'name' = new_files THEN
                old_files - 'blob_index' - 'index'
              END
            END
          END;
end; $ff$;
