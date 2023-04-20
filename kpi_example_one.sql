WITH final AS (WITH client_company_first_quote_date AS (
SELECT
bimissions.client_company_id,
bimissions.proposal_acceptance_date AS first_proposal_acceptance_date,
ROW_NUMBER()  OVER (PARTITION BY bimissions.client_company_id ORDER BY bimissions.proposal_acceptance_date ASC) as row_nb,
FROM `public.bimissions` AS bimissions
--LEFT JOIN `public.all_companies` AS all_companies ON all_companies.id = bimissions.client_company_id
WHERE bimissions.proposal_cancellation_date IS NULL
AND bimissions.proposal_acceptance_date IS NOT NULL
--AND bimissions.proposal_acceptance_date > all_companies.creation_date
),

first_quote_num AS (SELECT client_company_id, first_proposal_acceptance_date
FROM client_company_first_quote_date
WHERE row_nb = 1)
,
company_business_status AS (SELECT
aoc.opportunity_id,
fqn.first_proposal_acceptance_date,
CASE WHEN afs.creation_date	 > fqn.first_proposal_acceptance_date THEN TRUE
     WHEN fqn.first_proposal_acceptance_date IS NULL THEN FALSE
     ELSE FALSE
END AS company_already_did_mission,
--ROW_NUMBER() OVER (PARTITION BY aoc.client_company_id ORDER BY aoc.creation_date ASC) as row_b
FROM `opportunity.all_opportunity_core` as aoc
LEFT JOIN `opportunity.all_opportunity_funnel_steps` as afs ON afs.opportunity_id = aoc.opportunity_id
LEFT JOIN first_quote_num AS fqn ON fqn.client_company_id = aoc.client_company_id)
,
baseline AS (SELECT
CONCAT("M",DATE_DIFF(DATE_TRUNC(CURRENT_DATE(),MONTH), DATE_TRUNC(DATE(aoc.creation_date),MONTH), MONTH)) AS month,
allc.manager_country_code,
aoc.opportunity_id,
cbs.company_already_did_mission,
aobi.client_already_did_mission,
FROM opportunity.all_opportunity_core as aoc
LEFT JOIN public.all_companies as allc on allc.id = aoc.client_company_id
LEFT JOIN company_business_status as cbs on cbs.opportunity_id = aoc.opportunity_id
LEFT JOIN `opportunity.all_opportunity_business_impact` aobi ON aobi.opportunity_id = aoc.opportunity_id
WHERE DATE(aoc.creation_date)>=  DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 13 MONTH),MONTH)
AND team_name IN ('SDR Standard','SDR Prime')  
--AND row_b = 1
)

SELECT
manager_country_code,
month,
COUNT(DISTINCT CASE WHEN company_already_did_mission IS FALSE and client_already_did_mission IS FALSE THEN opportunity_id ELSE NULL END) AS nb_opport_marketing_generated_prospect
FROM baseline
GROUP BY 1,2
ORDER BY 1,2)

SELECT
      manager_country_code,
      CONCAT('Managed') AS segment,
      CONCAT('Prospect') AS prospect,
      CONCAT('No. of Marketing Generated Opportunities'),
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
      
FROM final

PIVOT(MAX(nb_opport_marketing_generated_prospect)
      FOR month
      IN ('M0','M1','M2','M3','M4','M5','M6','M7','M8','M9','M10','M11')
      )AS pivot_table
 GROUP BY 1
 ORDER BY 1
