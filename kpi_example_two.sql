SELECT
manager_country_code,
CONCAT('Managed') AS segment,
prospect,
CONCAT('Avg. of Basket'),
MAX(M0) AS M0,
MAX(M1) AS M1,
MAX(M2) AS M2,
MAX(M3) AS M3,
MAX(M4) AS M4,
MAX(M5) AS M5,
MAX(M6) AS M6,
MAX(M7) AS M7,
MAX(M8) AS M8,
MAX(M9) AS M9,
MAX(M10) AS M10,
MAX(M11) AS M11,
      FROM(SELECT 
      CONCAT("M",DATE_DIFF(DATE_TRUNC(CURRENT_DATE(),MONTH), DATE_TRUNC(DATE(aql.lot_start_date),MONTH), MONTH)) AS month,
      ac.manager_country_code,
      CASE WHEN (aql.business_relationship) = 'New client' THEN 'Prospect' 
      WHEN (aql.business_relationship) IN ('New mission','On-going business') THEN 'Returning Client' END AS prospect,
      --SAFE_DIVIDE(SUM(CASE WHEN ((ac.team_name) = 'SDR Prime' OR (ac.team_name) = 'SDR Standard') THEN lot_amount_excluding_taxes END), COUNT(DISTINCT CASE WHEN ((ac.team_name) = 'SDR Prime' OR (ac.team_name) = 'SDR Standard') THEN aql.mission_id END)) AS avg_basket_managed
      SAFE_DIVIDE(SUM(lot_amount_excluding_taxes), COUNT(DISTINCT aql.mission_id )) AS avg_basket_managed

FROM mission.all_quote_lots AS aql
LEFT JOIN public.all_companies AS ac ON ac.id = aql.client_company_id
WHERE lot_cancellation_date IS null
AND lot_start_date >= "2022-01-01"
AND manager_country_code IS NOT null
AND (ac.team_name) IN ('SDR Prime', 'SDR Standard')
GROUP BY 1,2,3
ORDER BY 1,2,3)

PIVOT (MAX(avg_basket_managed)
      FOR month
      IN ('M0','M1','M2','M3','M4','M5','M6','M7','M8','M9','M10','M11')
         ) AS pivot_table
         
 GROUP BY 1,2,3,4      
 ORDER BY 1,2,3

