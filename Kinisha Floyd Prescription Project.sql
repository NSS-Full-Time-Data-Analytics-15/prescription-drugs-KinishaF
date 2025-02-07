SELECT *
FROM drug;

/* Q1a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the 
npi and the total number of claims. NPI: 1881634483; Number: 99,707*/

SELECT npi, SUM(total_claim_count) AS highest_claim
FROM prescription
GROUP BY npi
ORDER BY highest_claim DESC
LIMIT 1;

/*Q1b Repeat the above, but this time report the nppes_provider_first_name,
nppes_provider_last_org_name, specialty_description, and the total number of claims*/

SELECT 
	   npi,
	   nppes_provider_first_name AS first_name,
	   nppes_provider_last_org_name AS last_name,
	   specialty_description, 
	   SUM(total_claim_count) AS total_claims
FROM prescriber LEFT JOIN prescription
USING(npi)
GROUP BY last_name, first_name, specialty_description, npi
ORDER BY total_claims DESC NULLS LAST
LIMIT 1;

--2a Which specialty had the most total number of claims (totaled over all drugs)? Family Practice--

SELECT specialty_description, SUM(total_claim_count) AS claim_count
FROM prescriber LEFT JOIN prescription 
USING(npi)
GROUP BY specialty_description
ORDER BY claim_count DESC NULLS LAST
LIMIT 1;

--2b Which specialty had the most total number of claims for opioids? Nurse Practitioner--

/*SELECT specialty_description AS specialty, SUM(total_claim_count) AS claim_count, opioid_drug_flag AS opiod_drug
FROM prescriber LEFT JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty, opioid_drug_flag
ORDER BY claim_count DESC*/

SELECT specialty_description AS specialty, SUM(total_claim_count) AS claim_count, opioid_drug_flag AS opiod_drug
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty, opioid_drug_flag
ORDER BY claim_count DESC
LIMIT 1;

/*2c. Challenge Question: Are there any specialities that appear in the prescriber table that have no
associated prescriptions in the prescription table?*/

SELECT DISTINCT specialty_description AS specialty, total_claim_count AS total_claims
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE total_claim_count IS NULL;

/*2d Difficult Bonus: For each specialty, report the percentage of total claims by that specialty which 
are for opioids. Which opecialities have a high percentage of opioids?*/

SELECT DISTINCT specialty_description, ROUND(SUM(total_claim_count) / total_claim_count, 2)AS percent_opioids, opioid_drug_flag
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug ON drug.drug_name = prescription.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY specialty_description, opioid_drug_flag, total_claim_count
ORDER BY specialty_description

--3a. Which drug (generic_name) had the highest total drug cost?

SELECT DISTINCT generic_name, SUM(total_drug_cost) AS total_cost
FROM drug INNER JOIN prescription USING(drug_name)
GROUP BY generic_name
ORDER BY total_cost DESC
LIMIT 1;

/*3b. Which drug (generic name) has the highest total cost per day? **Bonus: Round your cost per day
column to 2 decimal plances. Google ROUND to see how this works.**/

SELECT 
	generic_name,
	ROUND(SUM(total_drug_cost) / SUM(total_day_supply),2) AS cost_per_day
	FROM prescription INNER JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day DESC
LIMIT 1;


/*4a. For each drug in the drug table, return the drug name and then a column named 'drug_type' 
which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
**Hint:** You may want to use a CASE expression for this*/

SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	     ELSE 'neither' END AS drug_type 
FROM drug
ORDER BY drug_type ASC;

/*4b. Building off of the query you wrote for part a, determine whether more was spent 
(total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier 
comparision*/

SELECT 
	SUM(total_drug_cost)::money,
CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 ELSE 'neither' END AS drug_type
FROM drug AS d INNER JOIN prescription AS p USING(drug_name)
GROUP BY drug_type;

/*5a. How many CBSAs are in Tennessee? **Warning** The cbsa table contains information for all 
states, not just Tennessee*/

--Answer 42--
SELECT COUNT(cbsa)
FROM CBSA INNER JOIN fips_county USING(fipscounty)
WHERE state = 'TN';

/*5b. Which cbsa has the largest combined population? WHich has the smallest? Report the CBSA
name and total population*/
--Answer: Largest: Nashville-Davidson-Murfreesboro-Franklin,TN --
--Answer: Smallest: Morristown, TN

SELECT cbsaname, SUM(population) AS population
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY population
LIMIT 1; 

SELECT cbsaname, SUM(population) AS population
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER BY population DESC
LIMIT 1; 


/*5c. What is the largest (in terms of population) county which is not included in a CBSA? 
Report the CBSA name and total population*/

SELECT county, population
FROM fips_county LEFT JOIN population USING(fipscounty)
WHERE fipscounty NOT IN
(SELECT fipscounty FROM cbsa)
ORDER BY population DESC NULLS LAST
LIMIT 1;

/*6a. Find all rows in the prescription table where total_claims is at least 3000. Report the
drug_name and the total_claim_count*/

SELECT drug_name, total_claim_count AS total_claims
FROM prescription
WHERE total_claim_count >= 3000
ORDER BY drug_name;

/*6b. For each instance that you found in part a, add a column that indicates whether the drug
is an opioid*/

SELECT drug_name, total_claim_count AS total_claims, opioid_drug_flag AS opioid_drug
FROM prescription INNER JOIN drug USING(drug_name)
WHERE total_claim_count >= 3000
ORDER BY opioid_drug, drug_name;

/*6c. Add another column to your answer from the previous part which gives the prescriber first and 
last name associated with each row*/

SELECT 
	nppes_provider_first_name AS first_name,
	nppes_provider_last_org_name AS last_name,
	drug_name,
	total_claim_count AS total_claims,
	opioid_drug_flag AS opioid_drug
FROM prescription AS p1 INNER JOIN drug AS d USING(drug_name)
				  INNER JOIN prescriber AS p2 ON p2.npi = p1.npi
WHERE total_claim_count >= 3000
ORDER by drug_name;
				  
/*7. The goal of this exercise is to generat a full list of all pain management specialists in Nashville
and the number of claims they had for each opioid. **Hint** The results from all 3 parts will have 
637 rows*/

/*7a. First, create a list of all npi/drug_name combinations for pain management specialists in
(specialty_description = 'Pain Management') in the city of Nashville (nppes_provider_city = 'Nashville'),
where the drug is an opioid (opiod_drug_flag = 'Y'). ** Warning** Double-check your query before 
running it. You will only need to use the prescriber and drug tables since you don't need the claims 
numbers yet*/

SELECT npi, specialty_description AS specialty, nppes_provider_city AS city, drug_name, opioid_drug_flag AS opioid_drug
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' 
	  AND opioid_drug_flag = 'Y';

/*7b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations,
whether or not the prescriber had any claims. You should report the npi, the drug name, and the 
number of claims(total_claim_count).*/
	
SELECT npi,
	   specialty_description AS specialty,
	   nppes_provider_city AS city, 
	   drug_name, 
	   opioid_drug_flag AS opioid_drug,
	   total_claim_count
FROM prescriber
CROSS JOIN drug
FULL JOIN prescription USING(npi,drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' 
	  AND opioid_drug_flag = 'Y';

/*7c. Finally, if you have not done so already, fill in any missing values for 
total_claim_count with .0*/

SELECT npi,
	   specialty_description AS specialty,
	   nppes_provider_city AS city, 
	   drug_name, 
	   opioid_drug_flag AS opioid_drug,
	   COALESCE(total_claim_count, '0') AS total_claims
FROM prescriber
CROSS JOIN drug                               
FULL JOIN prescription USING(npi,drug_name)
WHERE specialty_description = 'Pain Management' AND nppes_provider_city = 'NASHVILLE' 
	  AND opioid_drug_flag = 'Y';




