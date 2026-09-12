CREATE DATABASE Comm_Log_Send_Reconciliation;
USE Comm_Log_Send_Reconciliation;

-- 7 campaign
select count(*) as campaign_count
from campaign;

-- 30 communication records
select count(*) as communication_log_count
from communication_log;

-- full raw data 
select * from communication_log;

-- campaign data raw 
select id, merchant_id, parent_id, name, creation_status, processing_status
from campaign
where merchant_id= 501
order by id;


select * from campaign where id= 9004;

-- 9004 has 4 commmnuniaction_log = 30-4 => 6
select count(*) as record_for_9004
from communication_log
where communication_id= 9004;

-- this gives 30 naive but ans is 22 
select count(*) as naive_count
from communication_log
where merchant_id =501
and communication_type='2'
and sent_time BETWEEN '2026-10-01' AND '2026-10-31';

-- gives 26 as almost all are approved 
SELECT COUNT(*) AS eligible_log_count
FROM communication_log cl
JOIN campaign c
    ON cl.communication_id = c.id
WHERE cl.merchant_id = 501
  AND cl.communication_type = '2'
  AND cl.sent_time >= '2026-10-01'
  AND cl.sent_time < '2026-11-01'
  AND c.creation_status IN ('approved', 'aborted', 'resumed', 'stopped')
  AND c.processing_status = 'processed';
  
  
SELECT
    communication_id,
    COUNT(*) AS send_attempts
FROM communication_log
WHERE merchant_id = 501
  AND communication_type = '2'
  AND sent_time >= '2026-10-01'
  AND sent_time < '2026-11-01'
GROUP BY communication_id
ORDER BY communication_id;

-- retry chain 
SELECT
    id,
    parent_id,
    name
FROM campaign
WHERE merchant_id = 501
ORDER BY id;

-- investigate chain 9001-> 9002-> 9003
SELECT
    communication_id,
    customer_id,
    delivery_status,
    sent_time
FROM communication_log
WHERE communication_id IN (9001, 9002, 9003)
ORDER BY customer_id, sent_time;


-- count raw attempts vs unique customers
SELECT COUNT(*) AS raw_attempts
FROM communication_log
WHERE communication_id IN (9001, 9002, 9003);

SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM communication_log
WHERE communication_id IN (9001, 9002, 9003);

-- investiagate standalone 9101
SELECT
    communication_id,
    customer_id,
    sent_time,
    delivery_status
FROM communication_log
WHERE communication_id = 9101
ORDER BY sent_time;

-- inverstigate 9201-> 9202
SELECT
    communication_id,
    customer_id,
    delivery_status,
    sent_time
FROM communication_log
WHERE communication_id IN (9201, 9202)
ORDER BY customer_id, sent_time;

-- unique gives 5 
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM communication_log
WHERE communication_id IN (9201, 9202);


SELECT
    SUM(final_count) AS target_base
FROM
(
    SELECT root_id,
        CASE
            -- Retry family:
            -- count each customer only once
            WHEN COUNT(DISTINCT communication_id) > 1
                THEN COUNT(DISTINCT customer_id)

            -- Standalone campaign:
            -- count every communication event
            ELSE COUNT(*)
        END AS final_count
    FROM
    (
        SELECT
            cl.communication_id,
            cl.customer_id,
            CASE
                WHEN c.parent_id IS NULL OR c.parent_id = 0
                    THEN c.id
                WHEN p.parent_id IS NULL OR p.parent_id = 0
                    THEN p.id
                ELSE p.parent_id
            END AS root_id
        FROM communication_log cl
        JOIN campaign c
            ON cl.communication_id = c.id
        LEFT JOIN campaign p
            ON c.parent_id = p.id
        WHERE cl.merchant_id = 501
          AND cl.communication_type = '2'
          AND cl.sent_time >= '2026-10-01'
          AND cl.sent_time < '2026-11-01'
          AND c.creation_status IN
              ('approved', 'aborted', 'resumed', 'stopped')
          AND c.processing_status = 'processed'
    ) AS eligible_logs
    GROUP BY root_id
) AS family_counts;










