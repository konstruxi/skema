
CREATE OR REPLACE 
VIEW {resources}_for_{target} AS
SELECT * from {resources}_current;

-- Create empty {resource} object
CREATE OR REPLACE FUNCTION
create_{resource}_for_{target}() returns trigger language plpgsql AS $$ begin
  if (new.errors is not null) then
    INSERT into {resources}_for_{target}({target}_id) VALUES(new.id);
  END IF;
  return new;
end $$;

CREATE TRIGGER create_{resource}_for_{target}
    AFTER INSERT ON {targets}
    FOR EACH ROW EXECUTE PROCEDURE create_{resource}_for_{target}();



-- Serialized with json
CREATE OR REPLACE 
VIEW {targets}_json AS
SELECT {targets}.*, 
{targets}_{resources}.{resources}_objects as {resources}
FROM {targets}_current {targets}
LEFT JOIN (
	SELECT {targets}.id, jsonb_agg({resources}) as {resources}_objects
	FROM {targets}_current {targets} 
	INNER JOIN {resources}_json {resources}
	ON ({targets}.root_id = {resources}.{target}_id) 
	GROUP BY {targets}.id
) {targets}_{resources} 
ON ({targets}_{resources}.id = {targets}.id);
