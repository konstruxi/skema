

CREATE OR REPLACE FUNCTION
inflection_singularize(text text) returns text language plpgsql AS $$ begin


return CASE
WHEN text is NULL         THEN NULL
WHEN text = ''            THEN ''
-- uncountable
WHEN text = 'equipment'   THEN 'equipment'
WHEN text = 'information' THEN 'information'
WHEN text = 'rice'        THEN 'rice'
WHEN text = 'money'       THEN 'money'
WHEN text = 'species'     THEN 'species'
WHEN text = 'series'      THEN 'series'
WHEN text = 'fish'        THEN 'fish'
WHEN text = 'sheep'       THEN 'sheep'
WHEN text = 'jeans'       THEN 'jeans'
 
-- irregular
WHEN text = 'people'      THEN 'person'
WHEN text = 'men'         THEN 'man'   
WHEN text = 'children'    THEN 'child' 
WHEN text = 'sexes'       THEN 'sex'   
WHEN text = 'moves'       THEN 'move'  
WHEN text = 'kine'        THEN 'cow'   
WHEN text = 'zombies'     THEN 'zombie'

-- singularization rules
WHEN text ~ '(database)s$' THEN 
  regexp_replace(text, '(database)s$', '\1')
WHEN text ~ '(quiz)zes$' THEN 
  regexp_replace(text, '(quiz)zes$', '\1')
WHEN text ~ '(matr)ices$' THEN 
  regexp_replace(text, '(matr)ices$', '\1ix')
WHEN text ~ '(vert|ind)ices$' THEN 
  regexp_replace(text, '(vert|ind)ices$', '\1ex')
WHEN text ~ '^(ox)en' THEN 
  regexp_replace(text, '^(ox)en', '\1')
WHEN text ~ '(alias|status)es$' THEN 
  regexp_replace(text, '(alias|status)es$', '\1')
WHEN text ~ '(octop|vir)i$' THEN 
  regexp_replace(text, '(octop|vir)i$', '\1us')
WHEN text ~ '(cris|ax|test)es$' THEN 
  regexp_replace(text, '(cris|ax|test)es$', '\1is')
WHEN text ~ '(shoe)s$' THEN 
  regexp_replace(text, '(shoe)s$', '\1')
WHEN text ~ '(o)es$' THEN 
  regexp_replace(text, '(o)es$', '\1')
WHEN text ~ '(bus)es$' THEN 
  regexp_replace(text, '(bus)es$', '\1')
WHEN text ~ '([m|l])ice$' THEN 
  regexp_replace(text, '([m|l])ice$', '\1ouse')
WHEN text ~ '(x|ch|ss|sh)es$' THEN 
  regexp_replace(text, '(x|ch|ss|sh)es$', '\1')
WHEN text ~ '(m)ovies$' THEN 
  regexp_replace(text, '(m)ovies$', '\1ovie')
WHEN text ~ '(s)eries$' THEN 
  regexp_replace(text, '(s)eries$', '\1eries')
WHEN text ~ '([^aeiouy]|qu)ies$' THEN 
  regexp_replace(text, '([^aeiouy]|qu)ies$', '\1y')
WHEN text ~ '([lr])ves$' THEN 
  regexp_replace(text, '([lr])ves$', '\1f')
WHEN text ~ '(tive)s$' THEN 
  regexp_replace(text, '(tive)s$', '\1')
WHEN text ~ '(hive)s$' THEN 
  regexp_replace(text, '(hive)s$', '\1')
WHEN text ~ '([^f])ves$' THEN 
  regexp_replace(text, '([^f])ves$', '\1fe')
WHEN text ~ '(^analy)ses$' THEN 
  regexp_replace(text, '(^analy)ses$', '\1sis')
WHEN text ~ '((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$' THEN 
  regexp_replace(text, '((a)naly|(b)a|(d)iagno|(p)arenthe|(p)rogno|(s)ynop|(t)he)ses$', '\1\2sis')
WHEN text ~ '([ti])a$' THEN 
  regexp_replace(text, '([ti])a$', '\1um')
WHEN text ~ '(n)ews$' THEN 
  regexp_replace(text, '(n)ews$', '\1ews')
ELSE 
  regexp_replace(text, 's$', '')
END;

END $$;




CREATE OR REPLACE FUNCTION
inflection_pluralize(text text) returns text language plpgsql AS $$ begin
return CASE 

WHEN text is NULL         THEN NULL
WHEN text = ''            THEN ''

-- uncountable
WHEN text = 'equipment'   THEN 'equipment'
WHEN text = 'information' THEN 'information'
WHEN text = 'rice'        THEN 'rice'
WHEN text = 'money'       THEN 'money'
WHEN text = 'species'     THEN 'species'
WHEN text = 'series'      THEN 'series'
WHEN text = 'fish'        THEN 'fish'
WHEN text = 'sheep'       THEN 'sheep'
WHEN text = 'jeans'       THEN 'jeans'
 
-- irregular
WHEN text = 'person'      THEN 'people'
WHEN text = 'man'         THEN 'men'
WHEN text = 'child'       THEN 'children'
WHEN text = 'sex'         THEN 'sexes'
WHEN text = 'move'        THEN 'moves'
WHEN text = 'cow'         THEN 'kine'
WHEN text = 'zombie'      THEN 'zombies'


-- pluralization rules
WHEN text ~ '(quiz)$' THEN
  regexp_replace(text, '(quiz)$', '\1zes')
WHEN text ~ '^(oxen)$' THEN
  regexp_replace(text, '^(oxen)$', '\1')
WHEN text ~ '^(ox)$' THEN
  regexp_replace(text, '^(ox)$', '\1en')
WHEN text ~ '([m|l])ice$' THEN
  regexp_replace(text, '([m|l])ice$', '\1ice')
WHEN text ~ '([m|l])ouse$' THEN
  regexp_replace(text, '([m|l])ouse$', '\1ice')
WHEN text ~ '([m|l])ouse$' THEN
  regexp_replace(text, '([m|l])ouse$', '\1ice')
WHEN text ~ '(matr|vert|ind)(?:ix|ex)$' THEN
  regexp_replace(text, '(matr|vert|ind)(?:ix|ex)$', '\1ices')
WHEN text ~ '(x|ch|ss|sh)$' THEN
  regexp_replace(text, '(x|ch|ss|sh)$', '\1es')
WHEN text ~ '([^aeiouy]|qu)y$' THEN
  regexp_replace(text, '([^aeiouy]|qu)y$', '\1ies')
WHEN text ~ '(hive)$' THEN
  regexp_replace(text, '(hive)$', '\1s')
WHEN text ~ '(?:([^f])fe|([lr])f)$' THEN
  regexp_replace(text, '(?:([^f])fe|([lr])f)$', '\1\2ves')
WHEN text ~ 'sis$' THEN
  regexp_replace(text, 'sis$', 'ses')
WHEN text ~ '([ti])a$' THEN
  regexp_replace(text, '([ti])a$', '\1a')
WHEN text ~ '([ti])um$' THEN
  regexp_replace(text, '([ti])um$', '\1a')
WHEN text ~ '(buffal|tomat)o$' THEN
  regexp_replace(text, '(buffal|tomat)o$', '\1oes')
WHEN text ~ '(bu)s$' THEN
  regexp_replace(text, '(bu)s$', '\1ses')
WHEN text ~ '(alias|status)$' THEN
  regexp_replace(text, '(alias|status)$', '\1es')
WHEN text ~ '(octop|vir)i$' THEN
  regexp_replace(text, '(octop|vir)i$', '\1i')
WHEN text ~ '(octop|vir)us$' THEN
  regexp_replace(text, '(octop|vir)us$', '\1i')
WHEN text ~ '(ax|test)is$' THEN
  regexp_replace(text, '(ax|test)is$', '\1es')
WHEN text ~ 's$' THEN
  regexp_replace(text, 's$', 's')
ELSE
  regexp_replace(text, '$', 's')
END;
END $$;




CREATE OR REPLACE FUNCTION inflections_slugify(str text) RETURNS text AS $$
BEGIN
  RETURN lower(trim(regexp_replace(str, '[^a-z0-9_-]+', '_', 'gi'), '_'));
END
$$ LANGUAGE plpgsql;