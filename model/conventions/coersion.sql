

CREATE OR REPLACE FUNCTION
kx_best_effort_jsonb(input anyelement) returns jsonb as $$
begin
  return input::jsonb;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;

CREATE OR REPLACE FUNCTION
kx_best_effort_text(input anyelement) returns text as $$
begin
  return input::jsonb;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;





CREATE OR REPLACE FUNCTION
kx_best_effort_integer(input anyelement) returns integer as $$
begin
  return input::integer;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;


CREATE OR REPLACE FUNCTION
kx_best_effort_uuid(input anyelement) returns uuid as $$
begin
  return input::uuid;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;


CREATE OR REPLACE FUNCTION
kx_best_effort_timestamptz(input anyelement) returns timestamptz as $$
begin
  return input::timestamptz;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;





CREATE OR REPLACE FUNCTION
kx_best_effort_bytea(input anyelement) returns bytea as $$
begin
  return null;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;


CREATE OR REPLACE FUNCTION
kx_best_effort_bytea_array(input anyelement) returns bytea[] as $$
begin
  return null;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;




CREATE OR REPLACE FUNCTION
kx_best_effort_xml(input anyelement) returns xml as $$
begin
  return xmlarticleroot(anyelement::xml, '', '');
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;




CREATE OR REPLACE FUNCTION
kx_best_effort_varchar(input anyelement) returns varchar as $$
begin
  return input::text;
exception 
  when others then
     return null;
end;
$$ language plpgsql immutable;

