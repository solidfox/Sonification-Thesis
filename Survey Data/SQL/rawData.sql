DROP TABLE IF EXISTS characterdata CASCADE;
CREATE TABLE characterdata (
	characterdataid		SERIAL PRIMARY KEY,
	time				timestamp,
	userid				text,
	kanji 				character,
	tries				decimal,
	helps				decimal,
	audio				boolean,
	iteration			int,
	session				int
);

\COPY characterdata FROM '../Raw Data/characterData.csv' DELIMITER ',' CSV

DROP TABLE IF EXISTS strokedata CASCADE;
CREATE TABLE strokedata (
	strokedataid	SERIAL PRIMARY KEY,
	time			timestamp,
	userid			text,
	kanji 			character,
	strokeindex		int,
	stroketype		character,
	tries			decimal,
	helps			decimal,
	audio			boolean,
	comparescore	decimal,
	startend 		text,
	session			int
);

\COPY strokedata FROM '../Raw Data/strokeData.csv' DELIMITER ',' CSV

DROP TABLE IF EXISTS debugusers CASCADE;
CREATE TABLE debugusers (
	userid			text PRIMARY KEY
);

\COPY debugusers FROM '../Raw Data/debugusers.csv' DELIMITER ',' CSV HEADER