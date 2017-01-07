
CREATE OR REPLACE 
VIEW {resources}_with_{target} AS
SELECT * from {resources}_current;


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
