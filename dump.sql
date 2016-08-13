--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.3
-- Dumped by pg_dump version 9.5.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


SET search_path = public, pg_catalog;

--
-- Name: convert_arrays(json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION convert_arrays(input json) RETURNS json
    LANGUAGE sql
    AS $_$ 
    SELECT concat('{', string_agg(to_json("key") || ':' || 
      (CASE WHEN value::text ~ '^\[[^\]]+\]$' THEN
              regexp_replace(
                regexp_replace(
                  regexp_replace(value::text, 
                    '"', '\\"', 'g'),
                  '\n', ' ', 'g'),
                '^\[([^\]]+)\]$', '"{\1}"')
            ELSE
              value::text
            END)
      , ','), '}')::json
    FROM json_each(input)

$_$;


ALTER FUNCTION public.convert_arrays(input json) OWNER TO root;

--
-- Name: create_item(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION create_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin

  -- merge over latest versions if given root_id

  IF new.root_id is not NULL and new.version is NULL THEN
    SELECT * FROM items WHERE id = new.root_id or root_id = new.root_id ORDER BY id DESC LIMIT 1 INTO old;
    new.created_at = old.created_at;
    new.version = old.version + 1;
    new.root_id = coalesce(old.root_id, new.root_id);
    new.comment = coalesce(new.comment, old.comment);

    new.order_id = coalesce(new.order_id, old.order_id);

 -- GENERATED: column names
  END IF;


  new.errors = validate_item(new);

  -- fill created_at, start with 0 version and return errors
  return (
    new.id,

    coalesce(new.root_id, new.id),          -- inherit root_id or set to self
    coalesce(new.version, 0),               -- start with 0 version unless given
    new.previous_version,                   -- point to previous version
    new.next_version,                       -- point to next version

    new.errors,
    coalesce(new.created_at, now()),        -- inherit or set creation timestamp
    coalesce(new.updated_at, now()),        -- inherit or set modification timestamp

    new.deleted_at,                         -- inherit deletion timestamp
 
    new.comment,

    new.order_id);                      -- GENERATED: column names
end $$;


ALTER FUNCTION public.create_item() OWNER TO root;

--
-- Name: create_order(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION create_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin

  -- merge over latest versions if given root_id

  IF new.root_id is not NULL and new.version is NULL THEN
    SELECT * FROM orders WHERE id = new.root_id or root_id = new.root_id ORDER BY id DESC LIMIT 1 INTO old;
    new.created_at = old.created_at;
    new.version = old.version + 1;
    new.root_id = coalesce(old.root_id, new.root_id);
    new.email = coalesce(new.email, old.email);

    new.name = coalesce(new.name, old.name);
    new.items_ids = coalesce(new.items_ids, old.items_ids);
 -- GENERATED: column names
  END IF;


  new.errors = validate_order(new);

  -- fill created_at, start with 0 version and return errors
  return (
    new.id,

    coalesce(new.root_id, new.id),          -- inherit root_id or set to self
    coalesce(new.version, 0),               -- start with 0 version unless given
    new.previous_version,                   -- point to previous version
    new.next_version,                       -- point to next version

    new.errors,
    coalesce(new.created_at, now()),        -- inherit or set creation timestamp
    coalesce(new.updated_at, now()),        -- inherit or set modification timestamp

    new.deleted_at,                         -- inherit deletion timestamp
 
    new.email,

    new.name,
    new.items_ids);                      -- GENERATED: column names
end $$;


ALTER FUNCTION public.create_order() OWNER TO root;

--
-- Name: create_variant(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION create_variant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin

  -- merge over latest versions if given root_id

  IF new.root_id is not NULL and new.version is NULL THEN
    SELECT * FROM variants WHERE id = new.root_id or root_id = new.root_id ORDER BY id DESC LIMIT 1 INTO old;
    new.created_at = old.created_at;
    new.version = old.version + 1;
    new.root_id = coalesce(old.root_id, new.root_id);
    new.comment = coalesce(new.comment, old.comment);

    new.item_id = coalesce(new.item_id, old.item_id);

 -- GENERATED: column names
  END IF;


  new.errors = validate_variant(new);

  -- fill created_at, start with 0 version and return errors
  return (
    new.id,

    coalesce(new.root_id, new.id),          -- inherit root_id or set to self
    coalesce(new.version, 0),               -- start with 0 version unless given
    new.previous_version,                   -- point to previous version
    new.next_version,                       -- point to next version

    new.errors,
    coalesce(new.created_at, now()),        -- inherit or set creation timestamp
    coalesce(new.updated_at, now()),        -- inherit or set modification timestamp

    new.deleted_at,                         -- inherit deletion timestamp
 
    new.comment,

    new.item_id);                      -- GENERATED: column names
end $$;


ALTER FUNCTION public.create_variant() OWNER TO root;

--
-- Name: delete_and_return_new(text, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_and_return_new(relname text, id integer) RETURNS json
    LANGUAGE plpgsql
    AS $_$DECLARE
  ret RECORD;
  root_id integer;
BEGIN
  
  EXECUTE 'SELECT root_id FROM ' || quote_ident(relname) || '_versions WHERE id=$1'
    INTO root_id USING id;
  
  EXECUTE 'DELETE FROM ' || quote_ident(relname) || '_versions  WHERE id=$1 RETURNING *'
    INTO ret USING id;
  
  EXECUTE 'SELECT * FROM ' || quote_ident(relname) || '_current  WHERE root_id=$1'
    INTO ret USING root_id;

  RETURN row_to_json(ret);
END;
$_$;


ALTER FUNCTION public.delete_and_return_new(relname text, id integer) OWNER TO root;

--
-- Name: delete_current_item(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_current_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  begin
    DELETE from items WHERE id=old.id;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_current_item() OWNER TO root;

--
-- Name: delete_current_order(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_current_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  begin
    DELETE from orders WHERE id=old.id;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_current_order() OWNER TO root;

--
-- Name: delete_current_variant(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_current_variant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  begin
    DELETE from variants WHERE id=old.id;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_current_variant() OWNER TO root;

--
-- Name: delete_item(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
  begin
    -- set deleted_at timestamp
    EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = now() WHERE id = $1' USING OLD.id;

    return null; -- dont delete original row
  end;
$_$;


ALTER FUNCTION public.delete_item() OWNER TO root;

--
-- Name: delete_item_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_item_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  DELETE from items_versions WHERE id=old.id;
  return null;
end; $$;


ALTER FUNCTION public.delete_item_head() OWNER TO root;

--
-- Name: delete_item_version(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_item_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare
    prev integer := item_head(old.root_id, true, old.previous_version + 1);
    next integer := (SELECT next_version from items WHERE version=prev and root_id = old.root_id);
  begin
    -- if there is no valid version to roll back to, mark as deleted if it isnt yet
    IF prev is null and old.deleted_at is null THEN
      DELETE FROM items_current WHERE id=old.id;
    ELSE
      
      -- otherwise clone preceeding version without deletion flag and make it current
      UPDATE items SET deleted_at=null, next_version=coalesce(next, old.version), root_id=-1
      WHERE root_id = old.root_id and version=coalesce(prev, old.version);
    END IF;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_item_version() OWNER TO root;

--
-- Name: delete_order(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
  begin
    -- set deleted_at timestamp
    EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = now() WHERE id = $1' USING OLD.id;

    return null; -- dont delete original row
  end;
$_$;


ALTER FUNCTION public.delete_order() OWNER TO root;

--
-- Name: delete_order_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_order_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  DELETE from orders_versions WHERE id=old.id;
  return null;
end; $$;


ALTER FUNCTION public.delete_order_head() OWNER TO root;

--
-- Name: delete_order_version(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_order_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare
    prev integer := order_head(old.root_id, true, old.previous_version + 1);
    next integer := (SELECT next_version from orders WHERE version=prev and root_id = old.root_id);
  begin
    -- if there is no valid version to roll back to, mark as deleted if it isnt yet
    IF prev is null and old.deleted_at is null THEN
      DELETE FROM orders_current WHERE id=old.id;
    ELSE
      
      -- otherwise clone preceeding version without deletion flag and make it current
      UPDATE orders SET deleted_at=null, next_version=coalesce(next, old.version), root_id=-1
      WHERE root_id = old.root_id and version=coalesce(prev, old.version);
    END IF;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_order_version() OWNER TO root;

--
-- Name: delete_variant(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_variant() RETURNS trigger
    LANGUAGE plpgsql
    AS $_$
  begin
    -- set deleted_at timestamp
    EXECUTE 'UPDATE ' || TG_TABLE_NAME || ' SET deleted_at = now() WHERE id = $1' USING OLD.id;

    return null; -- dont delete original row
  end;
$_$;


ALTER FUNCTION public.delete_variant() OWNER TO root;

--
-- Name: delete_variant_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_variant_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  DELETE from variants_versions WHERE id=old.id;
  return null;
end; $$;


ALTER FUNCTION public.delete_variant_head() OWNER TO root;

--
-- Name: delete_variant_version(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION delete_variant_version() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
  declare
    prev integer := variant_head(old.root_id, true, old.previous_version + 1);
    next integer := (SELECT next_version from variants WHERE version=prev and root_id = old.root_id);
  begin
    -- if there is no valid version to roll back to, mark as deleted if it isnt yet
    IF prev is null and old.deleted_at is null THEN
      DELETE FROM variants_current WHERE id=old.id;
    ELSE
      
      -- otherwise clone preceeding version without deletion flag and make it current
      UPDATE variants SET deleted_at=null, next_version=coalesce(next, old.version), root_id=-1
      WHERE root_id = old.root_id and version=coalesce(prev, old.version);
    END IF;
    return null;
  end;
$$;


ALTER FUNCTION public.delete_variant_version() OWNER TO root;

--
-- Name: full_select_sql(text, json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION full_select_sql(relname text, structure json) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
 ret json;
 names text;
 joins text;
BEGIN

  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    substr(value->>'name', 0, 2) as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(alias || '.json_agg as ' || prefix || 's', ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into names;


  WITH cols as (select
    value->>'name' as name,
    replace(value->>'name', '_id', '') as prefix,
    pluralize(replace(value->>'name', '_id', '')) as prefix_plural,
    substr(value->>'name', 0, 2) as alias,
    value
  from json_array_elements(structure)
  WHERE position('_ids' in value->>'name') = 0)

  SELECT
    string_agg(
      'LEFT JOIN (SELECT ' || relname || '.id, json_agg(' || prefix_plural || ')
       from ' || relname || ' 
       LEFT JOIN ' || prefix_plural || ' 
       ON (' || relname || '.' || name || ' = ' || prefix_plural || '.id) 
       GROUP BY ' || relname || '.id) ' || alias || ' 
       ON ' || alias || '.id = ' || relname || '.' || name, ',')
    FROM cols
    WHERE cols.name != 'root_id' and prefix != name
    into joins;


  RETURN 'SELECT ' || relname || '.* ' || (CASE WHEN names is not null THEN
      ', ' || names
    ELSE
      ''
    END) || ' from ' || relname || '_current as ' || relname || ' ' || coalesce(joins, '') || ' WHERE 1=1 ';
END;
$$;


ALTER FUNCTION public.full_select_sql(relname text, structure json) OWNER TO root;

--
-- Name: insert_sql(text, json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION insert_sql(relname text, structure json) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg('new.' || (els->>'name'), ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$$;


ALTER FUNCTION public.insert_sql(relname text, structure json) OWNER TO root;

--
-- Name: item_head(integer, boolean, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION item_head(integer, boolean DEFAULT true, integer DEFAULT 2147483646) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT version from items  WHERE root_id = $1 and version < $3 and 
       case when $2 then errors is null else true end 
       ORDER BY version DESC$_$;


ALTER FUNCTION public.item_head(integer, boolean, integer) OWNER TO root;

--
-- Name: json_from(text); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION json_from(relname text) RETURNS json
    LANGUAGE plpgsql
    AS $$DECLARE
 ret json;
 inputstring text;
BEGIN

  EXECUTE 'SELECT json_agg(r) FROM ( SELECT * FROM '|| quote_ident(relname) || ') r'
  INTO ret;
  RETURN ret  ;
END;
$$;


ALTER FUNCTION public.json_from(relname text) OWNER TO root;

--
-- Name: options_for(text, text, json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION options_for(relname text, preset text, structure json) RETURNS json
    LANGUAGE plpgsql
    AS $$ declare
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
        json_from(pluralize(replace(cols.name, '_id', '')) || '_current')
      end)
      FROM cols 
      WHERE cols.name != 'root_id'
      INTO options;

    return options;
END $$;


ALTER FUNCTION public.options_for(relname text, preset text, structure json) OWNER TO root;

--
-- Name: order_head(integer, boolean, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION order_head(integer, boolean DEFAULT true, integer DEFAULT 2147483646) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT version from orders  WHERE root_id = $1 and version < $3 and 
       case when $2 then errors is null else true end 
       ORDER BY version DESC$_$;


ALTER FUNCTION public.order_head(integer, boolean, integer) OWNER TO root;

--
-- Name: patch_sql(text, json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION patch_sql(relname text, structure json) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
 names text;
 values text;
BEGIN

  SELECT
    string_agg(els->>'name', ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into names;

  SELECT
    string_agg(CASE WHEN els->>'name' = 'root_id' THEN
      ':i:id'
    ELSE
      'new.' || (els->>'name')
    END, ', ')
    FROM json_array_elements(structure) els
    WHERE els->>'name' != 'id'
    into values;

  RETURN 'INSERT INTO ' || relname || '(' || names || ') SELECT ' || values;
END;
$$;


ALTER FUNCTION public.patch_sql(relname text, structure json) OWNER TO root;

--
-- Name: pluralize(text); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION pluralize(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$ begin
    return case when $1 = '' then
        ''
    else
        $1 || 's'
    end;
end $_$;


ALTER FUNCTION public.pluralize(text) OWNER TO root;

--
-- Name: singularize(text); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION singularize(text) RETURNS text
    LANGUAGE plpgsql
    AS $_$ begin
  return regexp_replace($1, 's$', '');
end $_$;


ALTER FUNCTION public.singularize(text) OWNER TO root;

--
-- Name: update_item(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_item() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  INSERT INTO items(
    root_id, version, previous_version, next_version, 
    created_at, updated_at,  deleted_at, 
    comment,

    order_id)                           -- GENERATED: column names
  VALUES (
    old.root_id,                            -- inherit root_id
    item_head(old.root_id, false) + 1,-- bump version to max + 1
    CASE WHEN new.root_id = -1 THEN
      old.previous_version
    ELSE
      old.version
    END,
    CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
      null
    ELSE
      new.next_version
    END,
    old.created_at,                         -- inherit creation timestamp 
    now(),                                  -- update modification timestamp
  
      new.deleted_at,                         -- inherit deletion timestamp
   
    new.comment,

    new.order_id);                      -- GENERATED: column names

  return null;                              -- keep row immutable
end $$;


ALTER FUNCTION public.update_item() OWNER TO root;

--
-- Name: update_item_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_item_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ declare
  next integer := item_head(new.root_id, true, coalesce(new.next_version, old.version) + 1);
begin
  UPDATE items SET updated_at=now(), root_id=-1 WHERE version=next;
  return null;
end; $$;


ALTER FUNCTION public.update_item_head() OWNER TO root;

--
-- Name: update_order(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_order() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  INSERT INTO orders(
    root_id, version, previous_version, next_version, 
    created_at, updated_at,  deleted_at, 
    email,

    name,
    items_ids)                           -- GENERATED: column names
  VALUES (
    old.root_id,                            -- inherit root_id
    order_head(old.root_id, false) + 1,-- bump version to max + 1
    CASE WHEN new.root_id = -1 THEN
      old.previous_version
    ELSE
      old.version
    END,
    CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
      null
    ELSE
      new.next_version
    END,
    old.created_at,                         -- inherit creation timestamp 
    now(),                                  -- update modification timestamp
  
      new.deleted_at,                         -- inherit deletion timestamp
   
    new.email,

    new.name,
    new.items_ids);                      -- GENERATED: column names

  return null;                              -- keep row immutable
end $$;


ALTER FUNCTION public.update_order() OWNER TO root;

--
-- Name: update_order_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_order_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ declare
  next integer := order_head(new.root_id, true, coalesce(new.next_version, old.version) + 1);
begin
  UPDATE orders SET updated_at=now(), root_id=-1 WHERE version=next;
  return null;
end; $$;


ALTER FUNCTION public.update_order_head() OWNER TO root;

--
-- Name: update_sql(text, json); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_sql(relname text, structure json) RETURNS text
    LANGUAGE plpgsql
    AS $$DECLARE
 names text;
BEGIN

  SELECT
    string_agg((els->>'name') || ' = coalesce(new.' || (els->>'name') || ', ' || relname || '.' || (els->>'name') || ')', ', ')
    FROM json_array_elements(structure) els
    into names;


  RETURN 'UPDATE ' || relname || ' SET ' || names;
END;
$$;


ALTER FUNCTION public.update_sql(relname text, structure json) OWNER TO root;

--
-- Name: update_variant(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_variant() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ begin
  INSERT INTO variants(
    root_id, version, previous_version, next_version, 
    created_at, updated_at,  deleted_at, 
    comment,

    item_id)                           -- GENERATED: column names
  VALUES (
    old.root_id,                            -- inherit root_id
    variant_head(old.root_id, false) + 1,-- bump version to max + 1
    CASE WHEN new.root_id = -1 THEN
      old.previous_version
    ELSE
      old.version
    END,
    CASE WHEN new.next_version = old.next_version and new.root_id != -1 THEN
      null
    ELSE
      new.next_version
    END,
    old.created_at,                         -- inherit creation timestamp 
    now(),                                  -- update modification timestamp
  
      new.deleted_at,                         -- inherit deletion timestamp
   
    new.comment,

    new.item_id);                      -- GENERATED: column names

  return null;                              -- keep row immutable
end $$;


ALTER FUNCTION public.update_variant() OWNER TO root;

--
-- Name: update_variant_head(); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION update_variant_head() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ declare
  next integer := variant_head(new.root_id, true, coalesce(new.next_version, old.version) + 1);
begin
  UPDATE variants SET updated_at=now(), root_id=-1 WHERE version=next;
  return null;
end; $$;


ALTER FUNCTION public.update_variant_head() OWNER TO root;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: items; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE items (
    id integer NOT NULL,
    root_id integer,
    version integer,
    previous_version integer,
    next_version integer,
    errors jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    comment text,
    order_id integer
);


ALTER TABLE items OWNER TO root;

--
-- Name: validate_item(items); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION validate_item(new items) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$ declare
  errors jsonb := '{}';
begin
  -- GENERATED: column validations
  IF NOT (new.comment is not null and new.comment != '' ) THEN
    SELECT jsonb_set(errors, '{comment}', '"Comment not provided"') into errors;
  END IF;

  IF NOT (new.order_id is not null) THEN
    SELECT jsonb_set(errors, '{order_id}', '"Items has to belong to order"') into errors;
  END IF;



  if errors::text = '{}' THEN
    errors = null;
  END IF;

  return errors;
end $$;


ALTER FUNCTION public.validate_item(new items) OWNER TO root;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE orders (
    id integer NOT NULL,
    root_id integer,
    version integer,
    previous_version integer,
    next_version integer,
    errors jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    email character varying(255),
    name character varying(255),
    items_ids integer[]
);


ALTER TABLE orders OWNER TO root;

--
-- Name: validate_order(orders); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION validate_order(new orders) RETURNS jsonb
    LANGUAGE plpgsql
    AS $_$ declare
  errors jsonb := '{}';
begin
  -- GENERATED: column validations
  IF NOT (new.email  ~ '^[^@]+@.+\..+$') THEN
    SELECT jsonb_set(errors, '{email}', '"Email is incorrect"') into errors;
  END IF;



  if errors::text = '{}' THEN
    errors = null;
  END IF;

  return errors;
end $_$;


ALTER FUNCTION public.validate_order(new orders) OWNER TO root;

--
-- Name: variants; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE variants (
    id integer NOT NULL,
    root_id integer,
    version integer,
    previous_version integer,
    next_version integer,
    errors jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    deleted_at timestamp with time zone,
    comment text,
    item_id integer
);


ALTER TABLE variants OWNER TO root;

--
-- Name: validate_variant(variants); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION validate_variant(new variants) RETURNS jsonb
    LANGUAGE plpgsql
    AS $$ declare
  errors jsonb := '{}';
begin
  -- GENERATED: column validations
  IF NOT (new.comment is not null and new.comment != '' ) THEN
    SELECT jsonb_set(errors, '{comment}', '"Comment not provided"') into errors;
  END IF;

  IF NOT (new.item_id is not null) THEN
    SELECT jsonb_set(errors, '{item_id}', '"Items has to belong to order"') into errors;
  END IF;



  if errors::text = '{}' THEN
    errors = null;
  END IF;

  return errors;
end $$;


ALTER FUNCTION public.validate_variant(new variants) OWNER TO root;

--
-- Name: variant_head(integer, boolean, integer); Type: FUNCTION; Schema: public; Owner: root
--

CREATE FUNCTION variant_head(integer, boolean DEFAULT true, integer DEFAULT 2147483646) RETURNS integer
    LANGUAGE sql IMMUTABLE STRICT
    AS $_$SELECT version from variants  WHERE root_id = $1 and version < $3 and 
       case when $2 then errors is null else true end 
       ORDER BY version DESC$_$;


ALTER FUNCTION public.variant_head(integer, boolean, integer) OWNER TO root;

--
-- Name: items_versions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW items_versions AS
 SELECT items.id,
    items.root_id,
    items.version,
    items.previous_version,
    items.next_version,
    items.errors,
    items.created_at,
    items.updated_at,
    items.deleted_at,
    items.comment,
    items.order_id
   FROM items
  WHERE (items.errors IS NULL)
  ORDER BY items.root_id, items.version DESC;


ALTER TABLE items_versions OWNER TO root;

--
-- Name: items_heads; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW items_heads AS
 SELECT DISTINCT ON (items_versions.root_id) items_versions.id,
    items_versions.root_id,
    items_versions.version,
    items_versions.previous_version,
    items_versions.next_version,
    items_versions.errors,
    items_versions.created_at,
    items_versions.updated_at,
    items_versions.deleted_at,
    items_versions.comment,
    items_versions.order_id
   FROM items_versions;


ALTER TABLE items_heads OWNER TO root;

--
-- Name: items_current; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW items_current AS
 SELECT items_heads.id,
    items_heads.root_id,
    items_heads.version,
    items_heads.previous_version,
    items_heads.next_version,
    items_heads.errors,
    items_heads.created_at,
    items_heads.updated_at,
    items_heads.deleted_at,
    items_heads.comment,
    items_heads.order_id
   FROM items_heads
  WHERE (items_heads.deleted_at IS NULL);


ALTER TABLE items_current OWNER TO root;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE items_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE items_id_seq OWNER TO root;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE items_id_seq OWNED BY items.id;


--
-- Name: variants_versions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW variants_versions AS
 SELECT variants.id,
    variants.root_id,
    variants.version,
    variants.previous_version,
    variants.next_version,
    variants.errors,
    variants.created_at,
    variants.updated_at,
    variants.deleted_at,
    variants.comment,
    variants.item_id
   FROM variants
  WHERE (variants.errors IS NULL)
  ORDER BY variants.root_id, variants.version DESC;


ALTER TABLE variants_versions OWNER TO root;

--
-- Name: variants_heads; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW variants_heads AS
 SELECT DISTINCT ON (variants_versions.root_id) variants_versions.id,
    variants_versions.root_id,
    variants_versions.version,
    variants_versions.previous_version,
    variants_versions.next_version,
    variants_versions.errors,
    variants_versions.created_at,
    variants_versions.updated_at,
    variants_versions.deleted_at,
    variants_versions.comment,
    variants_versions.item_id
   FROM variants_versions;


ALTER TABLE variants_heads OWNER TO root;

--
-- Name: variants_current; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW variants_current AS
 SELECT variants_heads.id,
    variants_heads.root_id,
    variants_heads.version,
    variants_heads.previous_version,
    variants_heads.next_version,
    variants_heads.errors,
    variants_heads.created_at,
    variants_heads.updated_at,
    variants_heads.deleted_at,
    variants_heads.comment,
    variants_heads.item_id
   FROM variants_heads
  WHERE (variants_heads.deleted_at IS NULL);


ALTER TABLE variants_current OWNER TO root;

--
-- Name: variants_json; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW variants_json AS
 SELECT variants_current.id,
    variants_current.root_id,
    variants_current.version,
    variants_current.previous_version,
    variants_current.next_version,
    variants_current.errors,
    variants_current.created_at,
    variants_current.updated_at,
    variants_current.deleted_at,
    variants_current.comment,
    variants_current.item_id
   FROM variants_current;


ALTER TABLE variants_json OWNER TO root;

--
-- Name: items_json; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW items_json AS
 SELECT items.id,
    items.root_id,
    items.version,
    items.previous_version,
    items.next_version,
    items.errors,
    items.created_at,
    items.updated_at,
    items.deleted_at,
    items.comment,
    items.order_id,
    items_variants.variants_objects AS variants
   FROM (items_current items
     LEFT JOIN ( SELECT items_1.id,
            jsonb_agg(variants.*) AS variants_objects
           FROM (items_current items_1
             JOIN variants_json variants ON ((items_1.root_id = variants.item_id)))
          GROUP BY items_1.id) items_variants ON ((items_variants.id = items.id)));


ALTER TABLE items_json OWNER TO root;

--
-- Name: items_with_order; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW items_with_order AS
 SELECT items_current.id,
    items_current.root_id,
    items_current.version,
    items_current.previous_version,
    items_current.next_version,
    items_current.errors,
    items_current.created_at,
    items_current.updated_at,
    items_current.deleted_at,
    items_current.comment,
    items_current.order_id
   FROM items_current;


ALTER TABLE items_with_order OWNER TO root;

--
-- Name: orders_versions; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW orders_versions AS
 SELECT orders.id,
    orders.root_id,
    orders.version,
    orders.previous_version,
    orders.next_version,
    orders.errors,
    orders.created_at,
    orders.updated_at,
    orders.deleted_at,
    orders.email,
    orders.name,
    orders.items_ids
   FROM orders
  WHERE (orders.errors IS NULL)
  ORDER BY orders.root_id, orders.version DESC;


ALTER TABLE orders_versions OWNER TO root;

--
-- Name: orders_heads; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW orders_heads AS
 SELECT DISTINCT ON (orders_versions.root_id) orders_versions.id,
    orders_versions.root_id,
    orders_versions.version,
    orders_versions.previous_version,
    orders_versions.next_version,
    orders_versions.errors,
    orders_versions.created_at,
    orders_versions.updated_at,
    orders_versions.deleted_at,
    orders_versions.email,
    orders_versions.name,
    orders_versions.items_ids
   FROM orders_versions;


ALTER TABLE orders_heads OWNER TO root;

--
-- Name: orders_current; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW orders_current AS
 SELECT orders_heads.id,
    orders_heads.root_id,
    orders_heads.version,
    orders_heads.previous_version,
    orders_heads.next_version,
    orders_heads.errors,
    orders_heads.created_at,
    orders_heads.updated_at,
    orders_heads.deleted_at,
    orders_heads.email,
    orders_heads.name,
    orders_heads.items_ids
   FROM orders_heads
  WHERE (orders_heads.deleted_at IS NULL);


ALTER TABLE orders_current OWNER TO root;

--
-- Name: orders_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE orders_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE orders_id_seq OWNER TO root;

--
-- Name: orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE orders_id_seq OWNED BY orders.id;


--
-- Name: orders_json; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW orders_json AS
 SELECT orders.id,
    orders.root_id,
    orders.version,
    orders.previous_version,
    orders.next_version,
    orders.errors,
    orders.created_at,
    orders.updated_at,
    orders.deleted_at,
    orders.email,
    orders.name,
    orders.items_ids,
    orders_items.items_objects AS items
   FROM (orders_current orders
     LEFT JOIN ( SELECT orders_1.id,
            jsonb_agg(items.*) AS items_objects
           FROM (orders_current orders_1
             JOIN items_json items ON ((orders_1.root_id = items.order_id)))
          GROUP BY orders_1.id) orders_items ON ((orders_items.id = orders.id)));


ALTER TABLE orders_json OWNER TO root;

--
-- Name: structures; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW structures AS
 SELECT columns.table_name,
    json_agg(columns.*) AS columns
   FROM ( SELECT tables.table_name,
            '' AS parent_name,
            '' AS grandparent_name,
            columns_1.column_name AS name,
                CASE
                    WHEN ("position"((columns_1.data_type)::text, 'character'::text) > 0) THEN 'string'::text
                    ELSE lower((columns_1.data_type)::text)
                END AS type,
            columns_1.character_maximum_length AS maxlength,
            ((((columns_1.column_name)::text <> 'id'::text) AND ((columns_1.column_name)::text <> 'root_id'::text) AND ("position"((columns_1.column_name)::text, 'version'::text) = 0)) OR NULL::boolean) AS is_editable,
            ((("position"((columns_1.column_name)::text, '_id'::text) > 0) AND ((columns_1.column_name)::text <> 'root_id'::text)) OR NULL::boolean) AS is_select,
            (((( SELECT c.column_name
                   FROM information_schema.columns c
                  WHERE (((c.table_name)::text = (tables.table_name)::text) AND (("position"((c.data_type)::text, 'character'::text) > 0) OR ((c.data_type)::text = 'text'::text)))
                 LIMIT 1))::text = (columns_1.column_name)::text) OR NULL::boolean) AS is_title
           FROM (information_schema.columns columns_1
             LEFT JOIN information_schema.tables tables ON (((tables.table_name)::text = (columns_1.table_name)::text)))
          WHERE (("position"((tables.table_name)::text, 'pg_'::text) = 0) AND ((tables.is_insertable_into)::text <> 'NO'::text) AND ("position"((tables.table_name)::text, 'sql_'::text) <> 1) AND ((tables.table_type)::text <> 'VIEW'::text))) columns
  GROUP BY columns.table_name;


ALTER TABLE structures OWNER TO root;

--
-- Name: structures_and_references; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW structures_and_references AS
 SELECT q.table_name,
    q.columns,
    x.refs AS "references"
   FROM (structures q
     LEFT JOIN ( SELECT structures.table_name,
            json_agg(y.*) AS refs
           FROM (structures
             JOIN structures y ON ((EXISTS ( SELECT json_array_elements.value
                   FROM json_array_elements(y.columns) json_array_elements(value)
                  WHERE ((json_array_elements.value ->> 'name'::text) = (singularize((structures.table_name)::text) || '_id'::text))))))
          GROUP BY structures.table_name) x ON (((x.table_name)::text = (q.table_name)::text)));


ALTER TABLE structures_and_references OWNER TO root;

--
-- Name: structures_and_children; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW structures_and_children AS
 SELECT q.table_name,
    q.columns,
    q."references",
    s.relations
   FROM (structures_and_references q
     LEFT JOIN ( SELECT structs.table_name,
            pluralize(replace((rls.value ->> 'name'::text), '_id'::text, ''::text)) AS relation,
            row_to_json(x.*) AS relations
           FROM structures structs,
            (LATERAL json_array_elements(structs.columns) rls(value)
             LEFT JOIN ( SELECT z.table_name,
                    json_agg(z.columns) AS columns
                   FROM ( SELECT structures.table_name,
                            structures.columns
                           FROM structures) z
                  GROUP BY z.table_name) x ON (((x.table_name)::text = pluralize(replace((rls.value ->> 'name'::text), '_id'::text, ''::text)))))
          WHERE (("position"((rls.value ->> 'name'::text), '_id'::text) > 0) AND ("position"((rls.value ->> 'name'::text), '_ids'::text) = 0) AND ((rls.value ->> 'name'::text) <> 'root_id'::text))) s ON (((q.table_name)::text = (s.table_name)::text)));


ALTER TABLE structures_and_children OWNER TO root;

--
-- Name: structures_hierarchy; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW structures_hierarchy AS
 SELECT structures.table_name,
    structures.columns,
    structures."references",
    structures.relations,
    pluralize(replace((parent.column_name)::text, '_id'::text, ''::text)) AS parent_name,
    pluralize(replace((grandparent.column_name)::text, '_id'::text, ''::text)) AS grandparent_name,
    ( SELECT q.columns
           FROM structures q
          WHERE ((q.table_name)::text = pluralize(replace((parent.column_name)::text, '_id'::text, ''::text)))
         LIMIT 1) AS parent_structure,
    ( SELECT q.columns
           FROM structures q
          WHERE ((q.table_name)::text = pluralize(replace((grandparent.column_name)::text, '_id'::text, ''::text)))
         LIMIT 1) AS grandparent_structure
   FROM ((structures_and_children structures
     LEFT JOIN ( SELECT columns.column_name,
            columns.table_name
           FROM information_schema.columns columns
        UNION
         SELECT ''::character varying,
            ''::character varying) parent ON (((((structures.table_name)::text = (parent.table_name)::text) AND ("position"((parent.column_name)::text, '_id'::text) > 0) AND ("position"((parent.column_name)::text, '_ids'::text) = 0) AND ((parent.column_name)::text <> 'root_id'::text)) OR ((parent.table_name)::text = ''::text))))
     LEFT JOIN ( SELECT columns.column_name,
            columns.table_name
           FROM information_schema.columns columns
        UNION
         SELECT ''::character varying,
            ''::character varying) grandparent ON ((((pluralize(replace((parent.column_name)::text, '_id'::text, ''::text)) = (grandparent.table_name)::text) AND (("position"((grandparent.column_name)::text, '_id'::text) > 0) AND ("position"((grandparent.column_name)::text, '_ids'::text) = 0)) AND ((grandparent.column_name)::text <> 'root_id'::text)) OR ((grandparent.table_name)::text = ''::text))));


ALTER TABLE structures_hierarchy OWNER TO root;

--
-- Name: structures_and_queries; Type: MATERIALIZED VIEW; Schema: public; Owner: root
--

CREATE MATERIALIZED VIEW structures_and_queries AS
 SELECT structures.table_name,
    structures.columns,
    structures."references",
    structures.relations,
    structures.parent_name,
    structures.grandparent_name,
    structures.parent_structure,
    structures.grandparent_structure,
        CASE
            WHEN (structures.parent_name <> ''::text) THEN replace(full_select_sql((structures.table_name)::text, structures.columns), 'WHERE 1=1'::text, (('WHERE '::text || singularize(structures.parent_name)) || '_id = $parent_id'::text))
            ELSE full_select_sql((structures.table_name)::text, structures.columns)
        END AS select_sql,
    update_sql((structures.table_name)::text, structures.columns) AS update_sql,
    patch_sql((structures.table_name)::text, structures.columns) AS patch_sql,
    insert_sql((structures.table_name)::text, structures.columns) AS insert_sql
   FROM structures_hierarchy structures
  WITH NO DATA;


ALTER TABLE structures_and_queries OWNER TO root;

--
-- Name: variants_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE variants_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE variants_id_seq OWNER TO root;

--
-- Name: variants_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE variants_id_seq OWNED BY variants.id;


--
-- Name: variants_with_item; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW variants_with_item AS
 SELECT variants_current.id,
    variants_current.root_id,
    variants_current.version,
    variants_current.previous_version,
    variants_current.next_version,
    variants_current.errors,
    variants_current.created_at,
    variants_current.updated_at,
    variants_current.deleted_at,
    variants_current.comment,
    variants_current.item_id
   FROM variants_current;


ALTER TABLE variants_with_item OWNER TO root;

--
-- Name: id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY items ALTER COLUMN id SET DEFAULT nextval('items_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY orders ALTER COLUMN id SET DEFAULT nextval('orders_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY variants ALTER COLUMN id SET DEFAULT nextval('variants_id_seq'::regclass);


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: root
--

COPY items (id, root_id, version, previous_version, next_version, errors, created_at, updated_at, deleted_at, comment, order_id) FROM stdin;
1	1	0	\N	\N	{"order_id": "Items has to belong to order"}	2016-08-01 15:13:28.134622+08	2016-08-01 15:13:28.134622+08	\N	a	\N
2	2	0	\N	\N	\N	2016-08-01 15:14:05.947196+08	2016-08-01 15:14:05.947196+08	\N	wefwefwef	2
3	3	0	\N	\N	{"comment": "Comment not provided"}	2016-08-01 15:19:22.192636+08	2016-08-01 15:19:22.192636+08	\N		2
4	4	0	\N	\N	\N	2016-08-01 15:19:24.292042+08	2016-08-01 15:19:24.292042+08	\N	vdfvdfv	2
5	5	0	\N	\N	\N	2016-08-03 11:51:24.130781+08	2016-08-03 11:51:24.130781+08	\N	aaasfdasf	2
6	6	0	\N	\N	\N	2016-08-03 11:51:25.118406+08	2016-08-03 11:51:25.118406+08	\N	aaasfdasf	2
7	7	0	\N	\N	\N	2016-08-03 11:51:25.54698+08	2016-08-03 11:51:25.54698+08	\N	aaasfdasf	2
8	8	0	\N	\N	\N	2016-08-03 11:51:31.049052+08	2016-08-03 11:51:31.049052+08	\N	rtfj	2
9	9	0	\N	\N	\N	2016-08-03 11:51:32.328405+08	2016-08-03 11:51:32.328405+08	\N	rtfj	2
10	10	0	\N	\N	\N	2016-08-03 11:51:32.96302+08	2016-08-03 11:51:32.96302+08	\N	rtfj	2
11	11	0	\N	\N	\N	2016-08-03 11:51:33.509401+08	2016-08-03 11:51:33.509401+08	\N	rtfj	2
12	12	0	\N	\N	\N	2016-08-03 11:51:34.170486+08	2016-08-03 11:51:34.170486+08	\N	rtfj	2
13	13	0	\N	\N	\N	2016-08-03 11:51:34.849806+08	2016-08-03 11:51:34.849806+08	\N	rtfj	2
14	11	1	\N	\N	\N	2016-08-03 11:51:33.509401+08	2016-08-03 12:08:16.113413+08	\N	rtfjdfbdb	2
15	11	2	\N	\N	\N	2016-08-03 11:51:33.509401+08	2016-08-09 16:53:21.467265+08	\N	rtfjdfbdb	4
16	16	0	\N	\N	{"comment": "Comment not provided"}	2016-08-09 17:05:37.038787+08	2016-08-09 17:05:37.038787+08	\N		2
17	17	0	\N	\N	\N	2016-08-09 17:05:39.679093+08	2016-08-09 17:05:39.679093+08	\N	eee	4
18	18	0	\N	\N	{"comment": "Comment not provided"}	2016-08-10 15:46:57.827197+08	2016-08-10 15:46:57.827197+08	\N		2
19	19	0	\N	\N	\N	2016-08-10 15:46:59.057498+08	2016-08-10 15:46:59.057498+08	\N	3	2
\.


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('items_id_seq', 19, true);


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: root
--

COPY orders (id, root_id, version, previous_version, next_version, errors, created_at, updated_at, deleted_at, email, name, items_ids) FROM stdin;
1	1	0	\N	\N	\N	2016-08-01 15:02:12.886172+08	2016-08-01 15:02:12.886172+08	\N	aaa@aa.aa	aa@aa.aa	\N
2	1	1	\N	\N	\N	2016-08-01 15:02:12.886172+08	2016-08-01 15:02:17.910301+08	\N	aaa@aa.a3a	aa@aa.aa	\N
3	3	0	\N	\N	\N	2016-08-03 11:49:06.340894+08	2016-08-03 11:49:06.340894+08	\N	da@aa.aa	a	\N
4	4	0	\N	\N	\N	2016-08-03 11:50:27.379471+08	2016-08-03 11:50:27.379471+08	\N	a@a.a	wdqwd	\N
5	5	0	\N	\N	\N	2016-08-03 11:50:28.647049+08	2016-08-03 11:50:28.647049+08	\N	a@a.a	wdqwd	\N
6	6	0	\N	\N	\N	2016-08-03 11:50:29.161991+08	2016-08-03 11:50:29.161991+08	\N	a@a.a	wdqwd	\N
7	7	0	\N	\N	\N	2016-08-03 11:50:30.409031+08	2016-08-03 11:50:30.409031+08	\N	da@aa.aa	a	\N
8	8	0	\N	\N	\N	2016-08-03 11:50:30.924361+08	2016-08-03 11:50:30.924361+08	\N	da@aa.aa	a	\N
9	9	0	\N	\N	{"email": "Email is incorrect"}	2016-08-05 13:33:31.703636+08	2016-08-05 13:33:31.703636+08	\N			\N
10	10	0	\N	\N	\N	2016-08-05 13:33:34.606567+08	2016-08-05 13:33:34.606567+08	\N	aaa@aa.aa		\N
11	10	1	\N	\N	\N	2016-08-05 13:33:34.606567+08	2016-08-05 13:33:46.752611+08	\N	aaa@aa<"'>.aa		\N
12	10	2	\N	\N	\N	2016-08-05 13:33:34.606567+08	2016-08-05 13:34:11.215686+08	\N	aaa@aa<"'>.aa4		\N
13	13	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:50:39.699755+08	2016-08-09 16:50:39.699755+08	\N			\N
14	14	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:51:27.890814+08	2016-08-09 16:51:27.890814+08	\N			\N
15	15	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:51:34.482905+08	2016-08-09 16:51:34.482905+08	\N			\N
16	16	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:52:11.816691+08	2016-08-09 16:52:11.816691+08	\N			\N
17	17	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:52:13.565748+08	2016-08-09 16:52:13.565748+08	\N			\N
18	18	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:52:14.932802+08	2016-08-09 16:52:14.932802+08	\N			\N
19	19	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 16:53:11.038313+08	2016-08-09 16:53:11.038313+08	\N			\N
20	20	0	\N	\N	{"email": "Email is incorrect"}	2016-08-09 21:55:46.663513+08	2016-08-09 21:55:46.663513+08	\N			\N
21	21	0	\N	\N	\N	2016-08-09 21:55:50.721049+08	2016-08-09 21:55:50.721049+08	\N	aaa@aa.aa	aaa@aa.aa	\N
22	22	0	\N	\N	\N	2016-08-12 17:49:43.909739+08	2016-08-12 17:49:43.909739+08	\N	\N	222	\N
23	23	0	\N	\N	\N	2016-08-12 18:17:17.840164+08	2016-08-12 18:17:17.840164+08	\N	\N	3	\N
24	24	0	\N	\N	\N	2016-08-12 18:29:56.766953+08	2016-08-12 18:29:56.766953+08	\N	abc@aaaa.aaa	\N	{1,2}
25	25	0	\N	\N	\N	2016-08-12 18:54:04.481877+08	2016-08-12 18:54:04.481877+08	\N	\N	3	\N
26	26	0	\N	\N	\N	2016-08-12 18:54:43.028836+08	2016-08-12 18:54:43.028836+08	\N	\N	3	\N
27	27	0	\N	\N	\N	2016-08-12 18:56:25.815001+08	2016-08-12 18:56:25.815001+08	\N	\N	3	\N
28	28	0	\N	\N	\N	2016-08-12 19:15:38.69693+08	2016-08-12 19:15:38.69693+08	\N	\N	3	\N
29	29	0	\N	\N	\N	2016-08-12 19:15:56.785458+08	2016-08-12 19:15:56.785458+08	\N	\N	3	\N
30	30	0	\N	\N	\N	2016-08-12 19:16:17.942625+08	2016-08-12 19:16:17.942625+08	\N	\N	3	\N
31	31	0	\N	\N	\N	2016-08-12 19:17:20.748784+08	2016-08-12 19:17:20.748784+08	\N	\N	3	\N
32	32	0	\N	\N	\N	2016-08-12 19:18:10.910571+08	2016-08-12 19:18:10.910571+08	\N	\N	3	\N
33	33	0	\N	\N	\N	2016-08-12 19:18:49.474012+08	2016-08-12 19:18:49.474012+08	\N	\N	3	\N
34	34	0	\N	\N	\N	2016-08-12 19:26:56.41451+08	2016-08-12 19:26:56.41451+08	\N	aaa@aa.aa	3	{4,5}
35	35	0	\N	\N	\N	2016-08-12 19:38:48.71904+08	2016-08-12 19:38:48.71904+08	\N	\N	3	\N
36	36	0	\N	\N	\N	2016-08-12 19:43:44.220304+08	2016-08-12 19:43:44.220304+08	\N	\N	3	\N
37	37	0	\N	\N	\N	2016-08-12 19:46:57.922869+08	2016-08-12 19:46:57.922869+08	\N	\N	3	\N
38	38	0	\N	\N	\N	2016-08-12 19:56:14.396094+08	2016-08-12 19:56:14.396094+08	\N	\N	3	\N
39	39	0	\N	\N	\N	2016-08-12 19:57:02.236514+08	2016-08-12 19:57:02.236514+08	\N	\N	3	\N
40	40	0	\N	\N	\N	2016-08-12 19:57:14.194167+08	2016-08-12 19:57:14.194167+08	\N	\N	3	\N
41	41	0	\N	\N	\N	2016-08-12 20:05:30.789737+08	2016-08-12 20:05:30.789737+08	\N	\N	3	\N
42	42	0	\N	\N	\N	2016-08-12 20:21:06.791842+08	2016-08-12 20:21:06.791842+08	\N	\N	3	\N
43	43	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 20:48:15.798815+08	2016-08-12 20:48:15.798815+08	\N	3	3	{4}
44	44	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 20:51:52.182471+08	2016-08-12 20:51:52.182471+08	\N	3	3	{4}
45	45	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 20:56:45.506652+08	2016-08-12 20:56:45.506652+08	\N	3	3	{4}
46	46	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:05:05.653264+08	2016-08-12 21:05:05.653264+08	\N	3	\N	\N
47	47	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:05:11.200842+08	2016-08-12 21:05:11.200842+08	\N	3	\N	\N
48	48	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:28:25.661133+08	2016-08-12 21:28:25.661133+08	\N	3		{4,6}
49	49	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:29:56.366531+08	2016-08-12 21:29:56.366531+08	\N	3		{4,6}
50	50	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:30:40.288549+08	2016-08-12 21:30:40.288549+08	\N	3		{4,6}
51	51	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:31:03.383561+08	2016-08-12 21:31:03.383561+08	\N	3		{4,6}
52	52	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:32:28.252392+08	2016-08-12 21:32:28.252392+08	\N	3		{4,6}
53	53	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:32:33.811247+08	2016-08-12 21:32:33.811247+08	\N	3		{4,6}
54	54	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:38:03.21471+08	2016-08-12 21:38:03.21471+08	\N	3		{4,6}
55	55	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:38:20.207174+08	2016-08-12 21:38:20.207174+08	\N	3		{4,6}
56	56	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:38:43.339274+08	2016-08-12 21:38:43.339274+08	\N	3		{4,6}
57	57	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:39:31.530664+08	2016-08-12 21:39:31.530664+08	\N	3		{4,6}
58	58	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:40:06.987517+08	2016-08-12 21:40:06.987517+08	\N	3		{4,6}
59	59	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:41:12.971518+08	2016-08-12 21:41:12.971518+08	\N	3		{4,6}
60	60	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:49:15.48435+08	2016-08-12 21:49:15.48435+08	\N	3		{4,6}
61	61	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:49:39.823607+08	2016-08-12 21:49:39.823607+08	\N	3		{4,6}
62	62	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:50:09.759358+08	2016-08-12 21:50:09.759358+08	\N	3		{4,6}
63	63	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:51:08.509087+08	2016-08-12 21:51:08.509087+08	\N	3		{4,6}
64	64	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:51:54.876779+08	2016-08-12 21:51:54.876779+08	\N	3		{4,6}
65	65	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:52:24.942492+08	2016-08-12 21:52:24.942492+08	\N	3		{4,6}
66	66	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:56:34.587265+08	2016-08-12 21:56:34.587265+08	\N	3		{2,4,6}
67	67	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:56:38.628859+08	2016-08-12 21:56:38.628859+08	\N	3		{2,6}
68	68	0	\N	\N	{"email": "Email is incorrect"}	2016-08-12 21:56:43.601763+08	2016-08-12 21:56:43.601763+08	\N	3		{2,5}
69	69	0	\N	\N	{"email": "Email is incorrect"}	2016-08-13 10:48:49.131331+08	2016-08-13 10:48:49.131331+08	\N			{2,5}
\.


--
-- Name: orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('orders_id_seq', 69, true);


--
-- Data for Name: variants; Type: TABLE DATA; Schema: public; Owner: root
--

COPY variants (id, root_id, version, previous_version, next_version, errors, created_at, updated_at, deleted_at, comment, item_id) FROM stdin;
1	1	0	\N	\N	\N	2016-08-01 15:14:57.128916+08	2016-08-01 15:14:57.128916+08	\N	23r23r23r	2
2	2	0	\N	\N	\N	2016-08-01 15:16:36.678254+08	2016-08-01 15:16:36.678254+08	\N	r23r	2
3	3	0	\N	\N	\N	2016-08-01 15:16:51.227624+08	2016-08-01 15:16:51.227624+08	\N	r23r	2
\.


--
-- Name: variants_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('variants_id_seq', 3, true);


--
-- Name: create_item; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER create_item BEFORE INSERT ON items FOR EACH ROW EXECUTE PROCEDURE create_item();


--
-- Name: create_order; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER create_order BEFORE INSERT ON orders FOR EACH ROW EXECUTE PROCEDURE create_order();


--
-- Name: create_variant; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER create_variant BEFORE INSERT ON variants FOR EACH ROW EXECUTE PROCEDURE create_variant();


--
-- Name: delete_current_item; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_current_item INSTEAD OF DELETE ON items_current FOR EACH ROW EXECUTE PROCEDURE delete_current_item();


--
-- Name: delete_current_order; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_current_order INSTEAD OF DELETE ON orders_current FOR EACH ROW EXECUTE PROCEDURE delete_current_order();


--
-- Name: delete_current_variant; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_current_variant INSTEAD OF DELETE ON variants_current FOR EACH ROW EXECUTE PROCEDURE delete_current_variant();


--
-- Name: delete_item; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_item BEFORE DELETE ON items FOR EACH ROW EXECUTE PROCEDURE delete_item();


--
-- Name: delete_item_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_item_head INSTEAD OF DELETE ON items_heads FOR EACH ROW EXECUTE PROCEDURE delete_item_head();


--
-- Name: delete_item_version; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_item_version INSTEAD OF DELETE ON items_versions FOR EACH ROW EXECUTE PROCEDURE delete_item_version();


--
-- Name: delete_order; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_order BEFORE DELETE ON orders FOR EACH ROW EXECUTE PROCEDURE delete_order();


--
-- Name: delete_order_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_order_head INSTEAD OF DELETE ON orders_heads FOR EACH ROW EXECUTE PROCEDURE delete_order_head();


--
-- Name: delete_order_version; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_order_version INSTEAD OF DELETE ON orders_versions FOR EACH ROW EXECUTE PROCEDURE delete_order_version();


--
-- Name: delete_variant; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_variant BEFORE DELETE ON variants FOR EACH ROW EXECUTE PROCEDURE delete_variant();


--
-- Name: delete_variant_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_variant_head INSTEAD OF DELETE ON variants_heads FOR EACH ROW EXECUTE PROCEDURE delete_variant_head();


--
-- Name: delete_variant_version; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER delete_variant_version INSTEAD OF DELETE ON variants_versions FOR EACH ROW EXECUTE PROCEDURE delete_variant_version();


--
-- Name: update_item; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_item BEFORE UPDATE ON items FOR EACH ROW EXECUTE PROCEDURE update_item();


--
-- Name: update_item_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_item_head INSTEAD OF UPDATE ON items_heads FOR EACH ROW EXECUTE PROCEDURE update_item_head();


--
-- Name: update_order; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_order BEFORE UPDATE ON orders FOR EACH ROW EXECUTE PROCEDURE update_order();


--
-- Name: update_order_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_order_head INSTEAD OF UPDATE ON orders_heads FOR EACH ROW EXECUTE PROCEDURE update_order_head();


--
-- Name: update_variant; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_variant BEFORE UPDATE ON variants FOR EACH ROW EXECUTE PROCEDURE update_variant();


--
-- Name: update_variant_head; Type: TRIGGER; Schema: public; Owner: root
--

CREATE TRIGGER update_variant_head INSTEAD OF UPDATE ON variants_heads FOR EACH ROW EXECUTE PROCEDURE update_variant_head();


--
-- Name: structures_and_queries; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: root
--

REFRESH MATERIALIZED VIEW structures_and_queries;


--
-- Name: public; Type: ACL; Schema: -; Owner: root
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM root;
GRANT ALL ON SCHEMA public TO root;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

