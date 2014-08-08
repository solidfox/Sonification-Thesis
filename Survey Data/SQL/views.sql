

DROP VIEW IF EXISTS "clean-character-data" CASCADE;
CREATE VIEW "clean-character-data" AS
	SELECT *, (
		SELECT count(*)
		FROM characterdata
		WHERE  time <= "outer".time 
			AND kanji = "outer".kanji
			AND session = "outer".session 
			AND userid = "outer".userid
	) AS sessioniteration,
	tries * strokes AS ntries,
	helps * strokes as nhelps
	FROM characterdata AS "outer" NATURAL JOIN kanjimetadata NATURAL JOIN experience
	WHERE NOT userid IN (SELECT * FROM debugusers)
			AND experience <= 1
			AND iteration > 1 
	ORDER BY userid, session, time
;

DROP VIEW IF EXISTS "clean-stroke-data" CASCADE;
CREATE VIEW "clean-stroke-data" AS
	SELECT *
	FROM strokedata
	WHERE NOT userid IN (SELECT * FROM debugusers)
	ORDER BY userid, session, time
;

DROP VIEW IF EXISTS "filtered-character-data" CASCADE;
CREATE VIEW "filtered-character-data" AS
	SELECT *
	FROM "clean-character-data"
	WHERE experience <= 1
		AND iteration > 1 
	ORDER BY userid, session, time
;

DROP VIEW IF EXISTS "user-audio-stats" CASCADE;
CREATE VIEW "user-audio-stats" AS
	SELECT 
		userid, 
		audio,
		session,
		sum(ntries)/sum(strokes) as "µtries",
		sum(nhelps)/sum(strokes) as "µhelps",
		count(distinct kanji) as "Characters",
		count(*) as "Iterations",
		CAST(count(*) as decimal)/CAST(count(distinct kanji) as decimal) "Iterations per Character"
	FROM "filtered-character-data"
	GROUP BY userid, audio, session
	ORDER BY userid, audio, session
;

DROP VIEW IF EXISTS "user-stats" CASCADE;
CREATE VIEW "user-stats" AS
	SELECT 
		userid, 
		session,
		sum(ntries)/sum(strokes) as "µtries",
		sum(nhelps)/sum(strokes) as "µhelps",
		audioBenefitTriesForUserAndSession(userid, session) as benefitForTries,
		audioBenefitHelpsForUserAndSession(userid, session) as benefitForHelps,
		count(*) as "Iterations",
		sum(strokes) as Strokes,
		min(experience) AS "Experience"
	FROM "filtered-character-data" NATURAL JOIN experience
	GROUP BY userid, session
	ORDER BY session, userid
;

DROP VIEW IF EXISTS "audio-stats" CASCADE;
CREATE VIEW "audio-stats" AS
	SELECT 
		audio, 
		session, 
		avg("µtries") as tries, 
		avg("µhelps") as helps, 
		avg("Iterations per Character") as iterations, 
		avg("Characters") as Characters
	FROM "user-audio-stats"
	GROUP BY audio, session
	ORDER BY session, audio
;

DROP VIEW IF EXISTS "session-stats" CASCADE;
CREATE VIEW "session-stats" AS
	SELECT 
		session,
		round(avg(benefitForHelps), 4) || ' ±' || round(confidenceInterval(
			count(benefitForHelps), 
			0.95, 
			stddev_samp(benefitForHelps)), 4) "Helps Benefit Mean 95% Confidence Interval",
		round(avg(benefitForTries), 4) || ' ±' || round(confidenceInterval(
			count(benefitForTries), 
			0.95, 
			stddev_samp(benefitForTries)), 4) "Tries Benefit Mean 95% Confidence Interval"
	FROM "user-stats"
	GROUP BY session
	ORDER BY session
;


CREATE OR REPLACE FUNCTION
audioBenefitTriesForUserAndSession(desireduserid text, desiredsession int)
RETURNS decimal
AS $$
DECLARE
	µTriesWithAudio decimal;
	µTriesWithNoAudio decimal;
	benefit decimal;
BEGIN
	SELECT sum(ntries)/sum(strokes) INTO µTriesWithAudio FROM "filtered-character-data"
		WHERE 	userid = desireduserid AND 
				session = desiredsession AND 
				audio = TRUE
	;
	
	SELECT sum(ntries)/sum(strokes) INTO µTriesWithNoAudio FROM "filtered-character-data" 
		WHERE 	userid = desireduserid AND 
				session = desiredsession AND 
				audio = FALSE
	;
	
	benefit := µTriesWithNoAudio - µTriesWithAudio;
	RETURN benefit;
END
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION
audioBenefitHelpsForUserAndSession(desireduserid text, desiredsession int)
RETURNS decimal
AS $$
DECLARE
	µHelpsWithAudio decimal;
	µHelpsWithNoAudio decimal;
	benefit decimal;
BEGIN
	SELECT sum(nhelps)/sum(strokes) INTO µHelpsWithAudio FROM "filtered-character-data"
		WHERE 	userid = desireduserid AND 
				session = desiredsession AND 
				audio = TRUE
	;
	
	SELECT sum(nhelps)/sum(strokes) INTO µHelpsWithNoAudio FROM "filtered-character-data" 
		WHERE 	userid = desireduserid AND 
				session = desiredsession AND 
				audio = FALSE
	;
	
	benefit := µHelpsWithNoAudio - µHelpsWithAudio;
	RETURN benefit;
END
$$ LANGUAGE plpgsql;






