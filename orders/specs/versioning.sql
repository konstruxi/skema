INSERT into {resources}({field}{extra_columns})  VALUES({'invalid1'}{extra_values});
{assert 'v0 insert initial invalid version',
version=0 and root_id=1 and {field}={'invalid1'} and errors->>{'field'} is not null and deleted_at is null and previous_version is null and next_version is null}

UPDATE {resources} SET {field}={'valid1'} WHERE {field}={'invalid1'};
{assert 'v1 Update initial invalid version into valid',
version=1 and root_id=1 and {field}={'valid1'} and errors->>{'field'} is null and deleted_at is null and previous_version = 0 and next_version is null}

UPDATE {resources} SET {field}={'invalid2'} WHERE {field}={'valid1'};
{assert 'v2 Turn valid version into invalid',
version=2 and root_id=1 and {field}={'invalid2'} and errors->>{'field'} is not null and deleted_at is null and previous_version = 1 and next_version is null}

UPDATE {resources} SET {field}={'valid2'} WHERE version=2;
{assert 'v3 Turn invalid version into valid again',
version=3 and root_id=1 and {field}={'valid2'} and errors->>{'field'} is null and deleted_at is null and previous_version = 2 and next_version is null}

DELETE from {resources}_current;
{assert 'v4 Soft delete of valid version',
version=4 and root_id=1 and {field}={'valid2'} and errors->>{'field'} is null and deleted_at is not null and previous_version = 3 and next_version is null}

DELETE from {resources}_heads;
{assert 'v5 Soft undelete',
version=5 and root_id=1 and {field}={'valid2'} and errors->>{'field'} is null and deleted_at is null and previous_version = 2 and next_version = 4}

UPDATE {resources} SET {field}={field} ||'p' WHERE version=5;
{assert 'v6 Append to versioned field',
version=6 and root_id=1 and {field}={'valid2'} || 'p' and errors->>{'field'} is null and deleted_at is null and previous_version = 5 and next_version is null}

DELETE from {resources}_versions WHERE version=4;
{assert 'v7 Roll back more than one version (to v3)',
version=7 and root_id=1 and {field}={'valid2'} and errors->>{'field'} is null and deleted_at is null and previous_version = 2 and next_version = 4}

DELETE from {resources}_heads;
{assert 'v8 Roll back skipping invalid version',
version=8 and root_id=1 and {field}={'valid1'} and errors->>{'field'} is null and deleted_at is null and previous_version = 0 and next_version = 7}

DELETE from {resources}_heads;
{assert 'v9 No valid version to roll back, mark as deleted',
version=9 and root_id=1 and {field}={'valid1'} and errors->>{'field'} is null and deleted_at is not null and previous_version = 8 and next_version is null}

DELETE from {resources}_heads;
{assert 'v10 Undelete version that couldnt roll back',
version=10 and root_id=1 and {field}={'valid1'} and errors->>{'field'} is null and deleted_at is null and previous_version = 0 and next_version = 7}

-- version 11 valid   -- redo applies 7th step
UPDATE {resources}_heads SET version = next_version WHERE root_id=1 and next_version is not null;
UPDATE {resources}_heads SET version = next_version WHERE root_id=1 and next_version is not null;
UPDATE {resources}_heads SET version = next_version WHERE root_id=1 and next_version is not null;
DELETE from {resources}_heads;
DELETE from {resources}_heads;
--DELETE from {resources}_heads;
--UPDATE {resources}_heads SET version = next_version WHERE root_id=1 and next_version is not null;
--
---- one extra valid order
--INSERT into {resources}({field})  VALUES('valid@c.com');
---- one extra invalid order
--INSERT into {resources}({field})  VALUES('d.com');

-- 2 current valid {resources}
SELECT * from {resources}_current;
-- 11 + 1 + 1 versions
SELECT * from {resources} ORDER BY id;
{assert 'Should create 16 versions' max(version) = 15}


CREATE OR REPLACE
VIEW orders_json AS
SELECT orders.*,
orders_items.items_json as items
FROM orders_current orders
LEFT JOIN (
	SELECT orders.id order_idz, jsonb_agg(items) as items_json
	FROM orders_current orders
	INNER JOIN items_json items
	ON (orders.root_id = items.order_id)
	GROUP BY orders.id
) orders_items
ON (orders_items.order_idz = orders.id);



SELECT * from orders_json;