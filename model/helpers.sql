CREATE OR REPLACE FUNCTION
singularize(text) returns text language plpgsql AS $$ begin
  return regexp_replace(regexp_replace($1, 'ies$', 'y'), 's$', '');
end $$;


CREATE OR REPLACE FUNCTION
pluralize(text) returns text language plpgsql AS $$ begin
    return case when $1 = '' then
        ''
    else
        $1 || 's'
    end;
end $$;
