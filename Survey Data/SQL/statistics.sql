DROP TABLE IF EXISTS "t-distribution";
CREATE TABLE "t-distribution" (
	degreesOfFreedom	int,
	t 					decimal,
	tailProbabilityMass decimal
);

\COPY "t-distribution" FROM '../Support Data/t-distribution.csv' DELIMITER ',' CSV

CREATE OR REPLACE FUNCTION
t(desiredDegreesOfFreedom int, desiredTailProbabilityMass numeric)
RETURNS decimal
AS $$
BEGIN
	RETURN (SELECT t FROM "t-distribution" 
		WHERE degreesOfFreedom = desiredDegreesOfFreedom
			AND tailProbabilityMass = desiredTailProbabilityMass);
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION
confidenceInterval(	sampleSize bigint, 
					confidenceLevel numeric, 
					sampleStandardDeviation numeric)
RETURNS decimal
AS $$
DECLARE
	degreesOfFreedom 		int;
	tailProbabilityMass 	numeric;
BEGIN
	degreesOfFreedom := sampleSize - 1;
	tailProbabilityMass := (1-confidenceLevel)/2;
	RETURN t(degreesOfFreedom, tailProbabilityMass) * sampleStandardDeviation / sqrt(sampleSize);
END
$$ LANGUAGE plpgsql;