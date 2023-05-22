DROP DATABASE IF EXISTS uf3_p3_emilio_nil;
CREATE DATABASE IF NOT EXISTS uf3_p3_emilio_nil;
USE uf3_p3_emilio_nil;

CREATE TABLE IF NOT EXISTS competicio
	(id_competicio 	SMALLINT		AUTO_INCREMENT,
    nom				VARCHAR(40)		NOT NULL,
    participants	SMALLINT		NOT NULL,
    any_fundacio	SMALLINT		NOT NULL,
    localitzacio    VARCHAR(50)     NOT NULL,
    tipus           ENUM('L','T')   NOT NULL,
    PRIMARY KEY (id_competicio),
    CONSTRAINT uk_competicio_nom 
    	UNIQUE (nom),
    CONSTRAINT ck_competicio_any_fundacio 
    	CHECK (any_fundacio >= 1800 AND any_fundacio <= 2022)
    )engine=InnoDB;

CREATE TABLE IF NOT EXISTS torneig 
	(id_competicio	SMALLINT,
	PRIMARY KEY (id_competicio),
	CONSTRAINT fk_torneig_competicio 
		FOREIGN KEY (id_competicio) REFERENCES competicio (id_competicio)
	)engine=InnoDB;

CREATE TABLE IF NOT EXISTS soci 
	(id_soci		INTEGER			AUTO_INCREMENT,
	nom				VARCHAR(50)		NOT NULL,
	cognoms			VARCHAR(100)	NOT NULL,
	data_naixement	DATE 			NOT NULL,
	nacionalitat	VARCHAR(50)		NOT NULL	DEFAULT 'Espanya',
	PRIMARY KEY (id_soci),
	CONSTRAINT ck_soci_data_naixement 
		CHECK (YEAR(data_naixement) > '1933')
	)engine=InnoDB;

CREATE TABLE IF NOT EXISTS entrenador 
	(id_entrenador	SMALLINT	AUTO_INCREMENT,
    nom				VARCHAR(15)	NOT NULL,
    cognom			VARCHAR(20) NOT NULL,
    edat			TINYINT(2) 	NOT NULL,
    nacionalitat	VARCHAR(20)	NOT NULL,
    PRIMARY KEY (id_entrenador),
    CONSTRAINT uk_entrenador_nom_cognom 
    	UNIQUE (nom, cognom),
    CONSTRAINT ck_entrenador_edat 
    	CHECK (edat >= 18 AND edat <= 75)
    )AUTO_INCREMENT = 101, engine=InnoDB;


CREATE TABLE IF NOT EXISTS estadi 
	(id_estadi		SMALLINT		AUTO_INCREMENT,
	nom				VARCHAR(35)		NOT NULL,
    capacitat		MEDIUMINT		NOT NULL,
    any_inauguracio	SMALLINT(4),
    pais			VARCHAR(20)		NOT NULL	DEFAULT ('Espanya'),
    PRIMARY KEY (id_estadi),
    CONSTRAINT ck_estadi_any_inauguracio 
    	CHECK (any_inauguracio > 1800 AND any_inauguracio <= 2022)
    )engine=InnoDB;


CREATE TABLE IF NOT EXISTS president 
	(id_president		SMALLINT		AUTO_INCREMENT,
	nom			 		VARCHAR(15)		NOT NULL,
	cognom				VARCHAR(30)		NOT NULL,
    edat				TINYINT(2)		NOT NULL,
    inici_presidencia	SMALLINT(4)		NOT NULL,
    PRIMARY KEY (id_president),
    CONSTRAINT ck_president_edat 
    	CHECK (edat >= 18 AND edat <= 90),
    CONSTRAINT ck_president_inici_presidencia 
    	CHECK (inici_presidencia >= 1980 AND inici_presidencia <= 2023)
	)engine=InnoDB;


CREATE TABLE IF NOT EXISTS club 
	(id_club		INTEGER			AUTO_INCREMENT,
    nom				VARCHAR(30)		NOT NULL,
    any_fundacio	SMALLINT		NOT NULL,
    pressupost		INTEGER,
    titols			TINYINT,
    pais			VARCHAR(20)		NOT NULL,
    entrenador_id	SMALLINT		NOT NULL,
    president_id	SMALLINT		NOT NULL,
    estadi_id		SMALLINT		NOT NULL,
    club_rival_id	INTEGER,
	PRIMARY KEY (id_club),
	CONSTRAINT uk_club_nom 
    	UNIQUE (nom),
    CONSTRAINT uk_club_entrenador_id 
    	UNIQUE (entrenador_id),
    CONSTRAINT uk_club_president_id 
    	UNIQUE (president_id),
    CONSTRAINT ck_club_any_fundacio 
    	CHECK (any_fundacio >= 1800 AND any_fundacio <= 2022),
    CONSTRAINT fk_club_entrenador 
    	FOREIGN KEY (entrenador_id) REFERENCES entrenador(id_entrenador),
    CONSTRAINT fk_club_estadi 
    	FOREIGN KEY (estadi_id) REFERENCES estadi(id_estadi),
    CONSTRAINT fk_club_president 
    	FOREIGN KEY (president_id) REFERENCES president(id_president),
    CONSTRAINT fk_club_club 
    	FOREIGN KEY (club_rival_id) REFERENCES club (id_club)
	)engine=InnoDB;

CREATE TABLE IF NOT EXISTS club_competicio 
	(id_club		INTEGER,
    id_competicio	SMALLINT,
    PRIMARY KEY (id_club, id_competicio),
    CONSTRAINT fk_club_competicio_club 
    	FOREIGN KEY (id_club) REFERENCES club (id_club),
    CONSTRAINT fk_club_competicio_competicio 
    	FOREIGN KEY (id_competicio) REFERENCES competicio (id_competicio)
    )engine=InnoDB;

CREATE TABLE IF NOT EXISTS club_soci 
	(id_club	INTEGER,
	id_soci		INTEGER,
	PRIMARY KEY (id_club, id_soci),
	CONSTRAINT fk_club_club_soci
		FOREIGN KEY (id_club) REFERENCES club (id_club),
	CONSTRAINT fk_soci_club_soci
		FOREIGN KEY (id_soci) REFERENCES soci (id_soci)
	)engine=InnoDB;

CREATE TABLE IF NOT EXISTS lliga 
	(id_competicio 		SMALLINT,
	PRIMARY KEY (id_competicio),
	CONSTRAINT fk_lliga_competicio 
		FOREIGN KEY (id_competicio) REFERENCES competicio (id_competicio)
	)engine=InnoDB;

CREATE TABLE IF NOT EXISTS classificacio 
	(id_club 			INTEGER		NOT NULL,
    punts               SMALLINT    NOT NULL,
    partits_jugats      SMALLINT    NOT NULL,
	competicio_id       SMALLINT	NOT NULL,
	PRIMARY KEY (id_club),
	CONSTRAINT classificacio_club 
		FOREIGN KEY (id_club) REFERENCES club (id_club),
	CONSTRAINT classificacio_competicio
		FOREIGN KEY (competicio_id) REFERENCES competicio (id_competicio)
	)engine=InnoDB;

ALTER TABLE club ADD INDEX any (any_fundacio);

ALTER TABLE club ADD INDEX pais (pais); 

CREATE INDEX nom_president ON president (nom);

CREATE INDEX nom_entrenador ON entrenador (nom);

/* Pràctica 3 - UF3 */

/* Funció per extreure el nom complert d'un soci mitjançant el seu id*/
DELIMITER //
CREATE OR REPLACE FUNCTION getNomSoci (IN inId_soci INT) 
RETURNS VARCHAR(40)
BEGIN
    DECLARE varNom VARCHAR(40);
    IF EXISTS (SELECT so.id_soci FROM soci so WHERE so.id_soci = inIdSoci) THEN
        SELECT CONCAT(so.nom,' ',so.cognoms) INTO varNom
        FROM soci so
        WHERE inIdSoci = so.id_soci;
    END IF;
    RETURN varNom;
END //
DELIMITER ;


/* Fer inserts de nous socis o actualitzar els existents.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE inserirSoci(OUT outError VARCHAR(100), IN inId_soci INT, IN inNom VARCHAR(50), IN inCognoms VARCHAR(100), IN inDataNaixement DATE, IN inNacionalitat VARCHAR(50), IN inId_club INT)
BEGIN
    DECLARE var_idsoci SMALLINT;
    SET outError := '';

    IF EXISTS (SELECT id_soci FROM soci WHERE id_soci = inId_soci) THEN
	    UPDATE soci
        SET nom = inNom, cognoms = inCognoms, data_naixement = inDataNaixement, nacionalitat = inNacionalitat
        WHERE id_soci = inId_soci;
    ELSEIF EXISTS (SELECT cl.id_club FROM club cl WHERE cl.id_club = inId_club) THEN
        INSERT INTO soci (nom, cognoms, data_naixement, nacionalitat) VALUES (inNom, inCognoms, inDataNaixement, inNacionalitat);
        SET var_idsoci = LAST_INSERT_ID();
        INSERT INTO club_soci (id_club, id_soci) VALUES (inId_club, var_idsoci);
    ELSE
        SET outError = 'Ja existeix el soci o ID de club incorrecte';
    END IF;
END //
DELIMITER ;


/* Procediment per consultar afiliacions de socis*/
DELIMITER //
CREATE OR REPLACE PROCEDURE consultaSociClub(OUT missatge VARCHAR(60), IN inIdSoci SMALLINT)
BEGIN
    IF EXISTS (SELECT so.id_soci FROM soci so WHERE so.id_soci = inIdSoci) THEN
        SELECT CONCAT(so.nom,' ',so.cognoms) AS Nom, cl.nom AS Club 
        FROM soci so
            INNER JOIN club_soci cs ON so.id_soci = cs.id_soci
            INNER JOIN club cl ON cs.id_club = cl.id_club
        WHERE inIdSoci = so.id_soci;
    END IF;
END //
DELIMITER ;


/* Procedimient per donar d'alta als clubs en competicions.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE inserirClubCompeticio(OUT outError VARCHAR(50), IN inId_club SMALLINT, IN inIdCompeticio SMALLINT)
BEGIN
    DECLARE participantsMax SMALLINT;
    DECLARE equipsInscrits SMALLINT;
    DECLARE esAUnaLliga BOOLEAN;

    SET outError = '';

    SET participantsMax = (SELECT participants FROM competicio WHERE id_competicio = inIdCompeticio);
    SET equipsInscrits = (SELECT COUNT(*) FROM club_competicio cc INNER JOIN competicio co ON cc.id_competicio = co.id_competicio WHERE co.id_competicio = inIdCompeticio);

    IF EXISTS (SELECT * FROM classificacio cla WHERE id_club = inId_club) AND (SELECT * FROM lliga WHERE id_competicio = inIdCompeticio) THEN 
        SET esAUnaLliga := 1; 
    ELSE 
        SET esAUnaLliga := 0; 
    END IF;
    
    
    IF EXISTS (SELECT id_club FROM club WHERE id_club = inId_club) THEN
        IF EXISTS (SELECT id_competicio FROM competicio WHERE id_competicio = inIdCompeticio) THEN
            IF (esAUnaLliga = 1) THEN
                SET outError := 'Un equip no pot estar a dues lligues.';
            ELSEIF(participantsMax > equipsInscrits) THEN
                INSERT INTO club_competicio (id_club, id_competicio) VALUES (inId_club, (SELECT id_competicio FROM competicio WHERE id_competicio = inIdCompeticio));
            ELSE
                SET outError = 'Competicio completa.';
            END IF;
        ELSE
            SET outError = 'No existeix la competicio.';
        END IF;
    ELSE
        SET outError = 'No existeix el club.';
    END IF;
END //
DELIMITER ;


/* Procedimient per consultar els equips participants en les diverses competicions.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE clubsPerCompeticio(OUT outError VARCHAR(50), IN inIdCompeticio SMALLINT)
BEGIN
    SET outError = '';

    IF EXISTS(SELECT co.id_competicio FROM competicio co WHERE co.id_competicio = inIdCompeticio) THEN
        SELECT cl.nom 
        FROM club cl 
            INNER JOIN club_competicio cc ON cl.id_club = cc.id_club
            INNER JOIN competicio co ON cc.id_competicio = co.id_competicio
        WHERE co.id_competicio = inIdCompeticio
        ORDER BY cl.nom;
    ELSE 
         SET outError = 'La competicio no existeix.';
    END IF;
END //
DELIMITER ;


/* Consultar classificacio en funcio de la lliga.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE classificacioLliga(OUT outError VARCHAR(50), IN inIdLliga SMALLINT)
BEGIN
    SET outError = '';
    IF EXISTS (SELECT DISTINCT(competicio_id) FROM classificacio WHERE competicio_id = inIdLliga) THEN
        SELECT cl.nom AS Club, cls.partits_jugats AS PJ, cls.punts AS PTS 
        FROM classificacio cls
            INNER JOIN lliga ll ON cls.competicio_id = ll.id_competicio
            INNER JOIN competicio co ON ll.id_competicio = co.id_competicio
            INNER JOIN club_competicio cc ON co.id_competicio = cc.id_competicio
            INNER JOIN club cl ON cc.id_club = cl.id_club
        WHERE cls.competicio_id = inIdLliga AND cc.id_club = cls.id_club
        ORDER BY cls.punts DESC;
    ELSE
        SET outError = 'No hi ha classificacio d''aquesta competicio.';
    END IF;
END //
DELIMITER ;

/* Procedimiento para actualizar jornadas de liga amb sentencia preparada.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE updateJornades(OUT error VARCHAR(100), IN inIdLliga SMALLINT, IN inEquip SMALLINT, IN inResultat ENUM('V','E','D'))
BEGIN
    DECLARE updateCla TEXT;
    SET updateCla := 'UPDATE classificacio SET';
    SET @equip := inEquip;
    SET error := ''; 
    IF EXISTS (SELECT * FROM classificacio WHERE id_club = inEquip AND competicio_id = inIdLliga) THEN
        IF (inResultat = 'V') THEN
            SET updateCla := CONCAT(updateCla,' punts = punts + 3,');
        ELSE
            SET updateCla := CONCAT(updateCla,' punts = punts + 1,');  
        END IF;

        SET updateCla := CONCAT(updateCla,' partits_jugats = partits_jugats + 1 WHERE id_club = @equip;');

        PREPARE stmt FROM updateCla;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    ELSE 
        SET error := 'Dades d''entrada invalides.';
    END IF;
END //
DELIMITER ;


/* Funció per saber el nom del club en funció del seu id*/
DELIMITER //
CREATE OR REPLACE FUNCTION getNomClub(inId_club INT) 
RETURNS VARCHAR(40)
BEGIN
    DECLARE nomClub VARCHAR(40);
    SELECT nom INTO nomClub FROM club WHERE id_club = inId_club;
    RETURN nomClub;
END //
DELIMITER ;


/* Disparador per afegir les competicions a la taula del seu tipus corresponent.*/
DELIMITER //
CREATE TRIGGER addClubLliga AFTER INSERT ON competicio FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE var_id_club SMALLINT;
    DECLARE var_id_competicio SMALLINT;
    DECLARE createClassificacio CURSOR FOR SELECT cc.id_club, cc.id_competicio FROM club_competicio cc WHERE id_competicio = NEW.id_competicio;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
    
    IF (NEW.tipus = 'L') THEN 
        INSERT INTO lliga VALUES (NEW.id_competicio);
    ELSEIF (NEW.tipus = 'T') THEN
        INSERT INTO torneig VALUES (NEW.id_competicio);
    END IF;
END //
DELIMITER ;


/* Cursor en disparador per afegir un club a la clasificacio de la liga un cop s'insereix un club a la competicio.*/
DELIMITER //
CREATE OR REPLACE TRIGGER createClassificacioLliga AFTER INSERT ON club_competicio FOR EACH ROW
BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE var_id_club SMALLINT;
    DECLARE var_id_competicio SMALLINT;
    DECLARE createClassificacio CURSOR FOR SELECT cc.id_club, cc.id_competicio FROM club_competicio cc WHERE id_competicio = NEW.id_competicio AND id_club = NEW.id_club;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    OPEN createClassificacio;

    loop_lliga: LOOP 
        FETCH FROM createClassificacio INTO var_id_club, var_id_competicio;

        IF done = 1 THEN
            LEAVE loop_lliga;
        END IF;

        INSERT INTO classificacio VALUES (var_id_club, 0, 0, var_id_competicio);

    END LOOP;
    CLOSE createClassificacio;
END //
DELIMITER ;


/* Fer update del pressupost i digui si ha augmentat o disminuit respecte l'any anterior*/
DELIMITER //
CREATE OR REPLACE PROCEDURE modificarPressupost(OUT missatge VARCHAR(60), IN inId_club SMALLINT, IN nou_pressupost INT)
BEGIN 
	DECLARE antic_pressupost INTEGER;
    DECLARE diferencia INTEGER;

	SELECT pressupost INTO antic_pressupost 
    FROM club 
    WHERE id_club = inId_club;
    
    UPDATE club 
    SET pressupost = nou_pressupost 
    WHERE id_club = inId_club;

    SET diferencia = nou_pressupost - antic_pressupost;

    IF (diferencia = 0) THEN
		SET missatge = 'No hi ha hagut cap variació respecte el pressupost anterior';
	
    ELSEIF (diferencia < 0) THEN 
		SET missatge = 'Ha disminuit respecte el pressupost anterior';
	
    ELSEIF (diferencia > 0) THEN
		SET missatge = 'Ha augmentat respecte el pressupost anterior';
	END IF;
END //
DELIMITER ;


/* Fer inserts o modificar dades de club.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE insertarClub(OUT outError VARCHAR(50), IN inId_club INT, IN inNom VARCHAR(30), IN inAnyFundacio SMALLINT, IN inPresupost INTEGER, IN inTitols TINYINT, IN inPais VARCHAR(20), IN inIdEntrenador SMALLINT, IN inIdEstadi SMALLINT, IN inIdPresident SMALLINT)
BEGIN
    DECLARE insertClub TEXT;
    SET insertClub := 'INSERT INTO club (';

    IF EXISTS (SELECT id_club FROM club WHERE id_club = inId_club) THEN
	    UPDATE club 
        SET nom = inNom, any_fundacio = inAnyFundacio, pressupost = inPressupost, titols = inTitols, pais = inPais, entrenador_id = inIdEntrenador, estadi_id = inIdEstadi, president_id = inIdPresident
        WHERE id_club = inId_club;
    ELSE
        IF (inId_club = NULL) THEN 
            SET insertClub := CONCAT(insertClub, 'nom, any_fundacio, pressupost, titols, pais, entrenador_id, estadi_id, president_id) VALUES (');
        ELSE 
            SET insertClub := CONCAT(insertClub, 'id_club, nom, any_fundacio, pressupost, titols, pais, entrenador_id, estadi_id, president_id) VALUES (inIdClub, ');
        END IF;
        
        SET insertClub := CONCAT(insertClub, 'inNom, inAnyFundacio, inPresupost, inTitols, inPais, inIdEntrenador, inIdEstadi, inIdPresident); ');
        PREPARE stmt FROM insertClub;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

    END IF;        
END //
DELIMITER ;


/* Procediment per inicialitzar classificacions de lligues.*/
DELIMITER //
CREATE OR REPLACE PROCEDURE reiniciaClassificacio(OUT missatge VARCHAR(60), IN inIdLliga SMALLINT)
BEGIN

    DECLARE done INT DEFAULT FALSE;
    DECLARE var_club_id, var_classificacio_id SMALLINT;
    DECLARE reiniciaClassificacio CURSOR FOR SELECT cla.id_club, cla.competicio_id FROM classificacio cla WHERE cla.competicio_id = inIdLliga;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN reiniciaClassificacio;

    read_loop: LOOP
        FETCH reiniciaClassificacio INTO var_club_id, var_classificacio_id;

        IF done THEN 
            LEAVE read_loop;
        END IF;

        UPDATE classificacio 
        SET punts = 0, partits_jugats = 0
        WHERE id_club = var_club_id AND competicio_id = var_classificacio_id;
    
    END LOOP;
    CLOSE reiniciaClassificacio;

END //
DELIMITER ;


/* Funció per veure quants clubs tenen un pressupost més elevat de N */
DELIMITER //
CREATE OR REPLACE FUNCTION majorPressupost(valor INT) 
RETURNS INT
BEGIN
    DECLARE pressupost INT;
    
    SELECT COUNT(*) INTO pressupost
    FROM club cl
    WHERE cl.pressupost > valor;
    
    RETURN pressupost;
END //
DELIMITER ;


/* Trigger que comprova que no varii en un 50% el pressupost 
dels clubs, fent saltar un error si es dona el cas.*/
DELIMITER //
CREATE OR REPLACE TRIGGER comprovaPressupost BEFORE UPDATE ON club FOR EACH ROW
BEGIN
    DECLARE error VARCHAR(25) DEFAULT 'Variacio major del 50%';
    IF (NEW.pressupost > OLD.pressupost + OLD.pressupost * 0.50) OR (NEW.pressupost < OLD.pressupost - OLD.pressupost * 0.50) AND (OLD.pressupost IS NOT NULL) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error;
    END IF;
END //
DELIMITER ;


/* Funció que comprova si dos clubs comparteixen estadi */
DELIMITER //
CREATE OR REPLACE FUNCTION mateixEstadi(a INT, b INT) 
RETURNS BOOLEAN
BEGIN
    RETURN (SELECT estadi_id FROM club WHERE id_club = a) = (SELECT estadi_id FROM club WHERE id_club = b);
END //
DELIMITER ;


/* Funcio que comprova si dos clubs s'enfrenten a una competicio.*/
DELIMITER //
CREATE OR REPLACE FUNCTION clubsRivals(club_a INT, club_b INT) 
RETURNS BOOLEAN
BEGIN
    RETURN (SELECT id_competicio FROM club_competicio WHERE id_club = club_a) IN (SELECT id_competicio FROM club_competicio WHERE id_club = club_b);
END //
DELIMITER ;

#Competicions
INSERT INTO competicio (nom, participants, any_fundacio, localitzacio, tipus) VALUES
	('LaLiga Santander', 18, 1850, 'Espanya', 'L'),
    ('EFL Championship', 24, 2004, 'Anglaterra', 'L'),
	('Premier League', 20, 1992, 'Anglaterra', 'L'),
	('Bundesliga', 18, 1962, 'Alemanya', 'L'),
	('Serie A', 20, 1898, 'Italia', 'L'),
	('Ligue 1', 20, 2002, 'França', 'L'), 
	('Eredivisie', 18, 1956, 'Holanda', 'L'),
	('Champions League', 64, 1955, 'Europa', 'T'), 
	('Copa del Rei', 116, 1902, 'Espanya', 'T'),
	('FA Cup', 732, 1871, 'Anglaterra', 'T'),
	('Coppa Italia', 78, 1922, 'Italia', 'T'),
	('Coupe de France', 1024, 1910, 'França', 'T'),
	('Eurocopa', 24, 1958, 'Europa', 'T');

#Entrenadors
INSERT INTO entrenador (nom, cognom, edat, nacionalitat) VALUES
	('Carlo', 'Ancelotti', 63, 'Italia'),
	('Xavi', 'Hernandez', 42, 'Espanya'), 
	('Diego Pablo', 'Simeone', 52, 'Argentina'),
	('Manuel', 'Pellegrini', 69, 'Chile'),
	('Ernesto', 'Valverde', 58, 'Espanya'), 
	('Imanol', 'Alguacil', 51, 'Espanya'), 
	('Gennaro', 'Gattuso', 44, 'Italia'),
	('Jagoba', 'Arrasate', 44, 'Espanya'),
	('Enrique', 'Setién', 64, 'Espanya'),
	('Vicente', 'Moreno', 48, 'Espanya'),
    ('Carlos', 'Corberán', 39, 'Espanya'),
    ('Paul', 'Heckingbottom', 45, 'Inglaterra'),
    ('Alex', 'Neil', 41, 'Escocia'),
    ('Aitor', 'Karanka', 49, 'Espanya'),
    ('Russell', 'Martin', 36, 'Escocia'),
    ('Liam', 'Rosenior', 37, 'Inglaterra'),
    ('Gary', 'Rowett', 48, 'Inglaterra'),
    ('Nigel', 'Pearson', 59, 'Inglaterra'),
    ('Mikel', 'Arteta', 40, 'Espanya'),
    ('Graham', 'Potter', 47, 'Inglaterra'),
    ('Jesse', 'Marsch', 49, 'EEUU'),
    ('Jürgen', 'Klopp', 55, 'Alemanya'),
    ('Pep', 'Guardiola', 52, 'Espanya'),
    ('Erik', 'Ten Hag', 53, 'Holanda'),
    ('Ruben', 'Selles', 39, 'Espanya'),
    ('Antonio', 'Conte', 53, 'Italia'),
    ('Julian', 'Nagelsmann', 35, 'Alemanya'),
    ('Edin', 'Terzic', 40, 'Alemanya'),
    ('Christian', 'Gross', 68, 'Suissa'),
    ('Xabi', 'Alonso', 41, 'Espanya'),
    ('Niko', 'Kovac', 51, 'Alemanya'),
    ('Urs', 'Fischer', 56, 'Suissa'),
    ('Christian', 'Streich', 57, 'Alemanya'),
    ('Marco', 'Rose', 46, 'Alemanya'),
    ('Massimiliano', 'Allegri', 55, 'Italia'),
    ('Simone', 'Inzaghi', 46, 'Italia'),
    ('Stefano', 'Pioli', 57, 'Italia'),
    ('Luciano', 'Spalletti', 63, 'Italia'),
    ('Jose', 'Mourinho', 60, 'Portugal'),
    ('Maurizio', 'Sarri', 64, 'Italia'),
    ('Alessio', 'Dionisi', 42, 'Italia'),
    ('Fabio', 'Liverani', 46, 'Italia'),
    ('Christophe', 'Galtier', 56, 'França'),
    ('Philippe', 'Clement', 48, 'França'),
    ('Paulo', 'Fonseca', 49, 'Portugal'),
    ('Laurent', 'Blanc', 57, 'França'),
    ('Franck', 'Haise', 51, 'França'),
    ('Igor', 'Tudor', 44, 'Croacia'),
    ('Bruno', 'Genesio', 56, 'França'),
    ('Didier', 'Digard', 36, 'França');
    

#Estadis
INSERT INTO estadi (nom, any_inauguracio, capacitat) VALUES 
	('Santiago Bernabeu', 1947, 81044), 
	('Spotify Camp Nou', 1957, 99354),
	('Wanda Metropolitano', 2017, 68456), 
	('Benito Villamarín', 2000, 60721), 
	('San Mames', 2013, 53289), 
	('Reale Arena', 1993, 39313), 
	('Mestalla', 1923, 49430),
	('El Sadar', 1967, 23576),
	('Estadio de la Ceràmica', 1923, 23500),
	('RCDE Stadium', 2009, 40000);
    
INSERT INTO estadi (nom, any_inauguracio, capacitat, pais) VALUES 
    ('The Hawthorns', 1900, 26688, 'Inglaterra'),
    ('Bramall Lane', 1955, 32609, 'Inglaterra'),
    ('bet365 Stadium', 1997, 30089, 'Inglaterra'),
    ('St.Andrews Stadium', 1906, 29409, 'Inglaterra'),
    ('Liberty Stadium', 2005, 20750, 'Inglaterra'),
    ('KCOM Stadium', 2002, 25404, 'Inglaterra'),
    ('The Den', 1993, 20146, 'Inglaterra'),
    ('Ashton Gate Stadium', 1887, 27000, 'Inglaterra'),
    ('Emirates Stadium', 2006, 60704, 'Inglaterra'),
    ('Stamford Bridge', 1877, 40834, 'Inglaterra'),
    ('Elland Road', 1897, 37890, 'Inglaterra'),
    ('Anfield', 1884, 53394, 'Inglaterra'),
    ('Etihad Stadium', 2003, 55017, 'Inglaterra'),
    ('Old Trafford', 1910, 74879, 'Inglaterra'),
    ('St Mary Stadium', 2001, 32505, 'Inglaterra'),
    ('Tottenham Hotspur Stadium', 2019, 62303, 'Inglaterra'),
    ('Allianz Arena', 2005, 75000, 'Alemanya'),
    ('Signal Iduna Park', 1974, 81365, 'Alemanya'),
    ('Veltins-Arena', 2001, 62271, 'Alemanya'),
    ('BayArena', 1958, 30210, 'Alemanya'),
    ('Volkswagen Arena', 2002, 30000, 'Alemanya'),
    ('Stadion An der Alten Försterei', 1920, 22012, 'Alemanya'),
    ('Schwarzwald-Stadion', 1954, 24000, 'Alemanya'),
    ('Red Bull Arena Leipzig', 2004, 42959, 'Alemanya'),
    ('Allianz Stadium', 2011, 41507, 'Italia'),
    ('San Siro', 1926, 75923, 'Italia'),
    ('Stadio Diego Armando Maradona', 1959, 60240, 'Italia'),
    ('Stadio Olimpico', 1937, 70634, 'Italia'),
    ('Mapei Stadium-Città del Tricolore', 1995, 23717, 'Italia'),
    ('Stadio Ennio Tardini', 1923, 23895, 'Italia'),
    ('Parc Des Princes', 1972, 47929, 'França'),
    ('Stade Louis II', 1985, 18523, 'França'),
    ('Stade Pierre-Mauroy', 2012, 50186, 'França'),
    ('Groupama Stadium', 2016, 59186, 'França'),
    ('Stade Bollaert-Delelis', 1933, 38223, 'França'),
    ('Stade Vélodrome', 1937, 67394, 'França'),
    ('Roazhon Park', 1912, 29778, 'França'),
    ('Allianz Rivera', 2013, 35624, 'França');

#Presidents
INSERT INTO president (nom, cognom, edat, inici_presidencia) VALUES
	('Florentino', 'Perez', 75, 2009),
	('Joan', 'Laporta', 60, 2021),
	('Enrique', 'Cerezo', 74, 2003),
	('Angel', 'Haro', 48, 2016),
	('Jon', 'Uriarte', 43, 2022),
	('Jokin', 'Aperribay', 56, 2008),
	('Lay', 'Hoon', 49, 2022),
	('Luis', 'Sabalza', 75, 2014),
	('Fernando', 'Roig', 75, 1997),
	('Chen', 'Yansheng', 52, 2016),
    ('Li', 'Piyue', 50, 2018),
    ('Musaad', 'bin Khalid', 30, 2019),
    ('Peter', 'Coates', 85, 2006),
    ('Maxi', 'Lopez', 38, 2022),
    ('Julian', 'Winter', 57, 2020),
    ('Acun', 'Illicali', 53, 2022),
    ('John', 'Berlyson', 62, 2012),
    ('Stephen', 'Lansdow', 57, 2010),
    ('Stan', 'Kroenke', 75, 2008),
    ('Todd', 'Boehly', 49, 2022),
    ('Andrea', 'Radizzani', 49, 2017),
    ('John', 'Henry', 73, 2010),
    ('Sheikh', 'Mansour', 52, 2008),
    ('Joel', 'Glazer', 52, 2005),
    ('Katharina', 'Liebherr', 52, 2017),
    ('Joe', 'Lewis', 86, 2012),
    ('Herbert', 'Hainer', 68, 2019),
    ('Hans-Joachim', 'Watzke', 64, 2005),
    ('Axel', 'Hefer', 53, 2021),
    ('Fernando', 'Carro', 58, 2018),
    ('Francisco', 'Garcia', 65, 2009),
    ('Dirk', 'Zingler', 58, 2004),
    ('Eberhard', 'Fugman', 69, 2011),
    ('Oliver', 'Mintzlaff', 49, 2017),
    ('Gianluca', 'Ferrero', 59, 2022),
    ('Steven', 'Zhang', 32, 2016),
    ('Paolo', 'Scaroni', 76, 2018),
    ('Aurelio', 'Di Laurentis', 73, 2004),
    ('Dan', 'Friedkin', 57, 2023),
    ('Claudio', 'Lotito', 65, 2004),
    ('Carlo', 'Rossi', 67, 2008),
    ('Kyle', 'Krause', 53, 2017),
    ('Nasser', 'Al-Khelaifi', 51, 2011),
    ('Dmitri', 'Yevguénievich', 64, 2011),
    ('Olivier', 'Létang', 70, 2020),
    ('Jean-Michel', 'Aulas', 74, 1997),
    ('Joseph', 'Oughourlian', 50, 2018),
    ('Pablo', 'Longoria', 34, 2021),
    ('Nicolas', 'Holvek', 51, 2020),
    ('Jean-Pierre', 'Rivère', 65, 2011);

#Clubs
INSERT INTO club (nom, any_fundacio, pais, entrenador_id, president_id, estadi_id) VALUES 
	('Real Madrid FC', 1902, 'Espanya', 101, 1, 1),
	('Real Betis Balonpie', 1907, 'Espanya', 104, 4, 4),
	('Athletic Club', 1964, 'Espanya', 105, 5, 5),
	('Real Sociedad', 1909, 'Espanya', 106, 6, 6),
	('Valencia Club de Futbol', 1919, 'Espanya', 107, 7, 7),
	('Club Atletico Osasuna', 1920, 'Espanya', 108, 8, 8),
	('Villarreal CF', 1923, 'Espanya', 109, 9, 9);
INSERT INTO club (nom, any_fundacio, pais, entrenador_id, president_id, estadi_id, club_rival_id) VALUES 
	('FC Barcelona', 1899, 'Espanya', 102, 2, 2, 1),
	('Atletico de Madrid', 1903, 'Espanya', 103, 3, 3, 1);
INSERT INTO club (nom, any_fundacio, pressupost, pais, entrenador_id, president_id, estadi_id) VALUES 
	('RCD Espanyol', 1900, 8900000, 'Espanya', 110, 10, 10);
INSERT INTO club (nom, any_fundacio, titols, pais, entrenador_id, president_id, estadi_id) VALUES 
	('West Bromwich', 1878, 5, 'Inglaterra', 111, 11, 11),
    ('Sheffield United', 1889, 1, 'Inglaterra', 112, 12, 12),
    ('Stoke City', 1863, 2, 'Inglaterra', 113, 13, 13),
    ('Birmingham City', 1875, 2, 'Inglaterra', 114, 14, 14),
    ('Swansea City', 1912, 0, 'Inglaterra', 115, 15, 15),
    ('Hull City', 1904, 0, 'Inglaterra', 116, 16, 16),
    ('Milwall', 1885, 0, 'Inglaterra', 117, 17, 17),
    ('Bristol City', 1894, 0, 'Inglaterra', 118, 18, 18),
    ('Arsenal FC', 1886, 31, 'Inglaterra', 119, 19, 19),
    ('Chelsea FC', 1905, 22, 'Inglaterra', 120, 20, 20),
    ('Leeds United FC', 1919, 8, 'Inglaterra', 121, 21, 21),
    ('Liverpool FC', 1892, 47, 'Inglaterra', 122, 22, 22),
    ('Manchester City', 1880, 14, 'Inglaterra', 123, 23, 23),
    ('Manchester United', 1878, 66, 'Inglaterra', 124, 24, 24),
    ('Southampton FC', 1885, 0, 'Inglaterra', 125, 25, 25),
    ('Tottenham Hotspur FC', 1882, 26, 'Inglaterra', 126, 26, 26),
    ('Bayern de Munich', 1900, 72, 'Alemanya', 127, 27, 27),
    ('Borussia de Dortmund', 1909, 19, 'Alemanya', 128, 28, 28),
    ('Schalke 04', 1904, 7, 'Alemanya', 129, 29, 29),
    ('Bayer Leverkusen', 1904, 1, 'Alemanya', 130, 30, 30),
    ('Wolfsburgo', 1945, 1, 'Alemanya', 131, 31, 31),
    ('Union Berlin', 1966, 0, 'Alemanya', 132, 32, 32),
    ('Friburgo', 1904, 0, 'Alemanya', 133, 33, 33),
    ('RB Leipzig', 2009, 0, 'Alemanya', 134, 34, 34),
    ('Juventus', 1897, 66, 'Italia', 135, 35, 35),
    ('Inter de Milan', 1908, 21, 'Italia', 136, 36, 36),
    ('AC Milan', 1899, 48, 'Italia', 137, 37, 36),
    ('AS Napoli', 1926, 12, 'Italia', 138, 38, 37),
    ('AS Roma', 1927, 9, 'Italia', 139, 39, 38),
    ('AS Lazio', 1900, 3, 'Italia', 140, 40, 38),
    ('Sassuolo', 1920, 0, 'Italia', 141, 41, 39),
    ('Parma', 1913, 3, 'Italia', 142, 42, 40),
    ('PSG', 1970, 43, 'França', 143, 43, 41),
    ('AS Monaco', 1924, 8, 'França', 144, 44, 42),
    ('Lille', 1944, 4, 'França', 145, 45, 43),
    ('OL Lyon', 1950, 23, 'França', 146, 46, 44),
    ('Lens', 1906, 1, 'França', 147, 47, 45),
    ('OL Marseille', 1899, 30, 'França', 148, 48, 46),
    ('Stade de Rennais', 1901, 3, 'França', 149, 49, 47),
    ('OGC Niza', 1904, 4, 'França', 150, 50, 48);
    

#Clubs i competicions
INSERT INTO club_competicio (id_club, id_competicio) VALUES 
	(1,1), 
	(2,1), 
	(3,1), 
	(4,1), 
	(5,1), 
	(6,1), 
	(7,1), 
	(8,1), 
	(9,1), 
	(10,1),
    (11,2),
    (12,2),
    (13,2),
    (14,2),
    (15,2),
    (16,2),
    (17,2),
    (18,2),
    (19,3),
    (20,3),
    (21,3),
    (22,3),
    (23,3),
    (24,3),
    (25,3),
    (26,3),
    (27,4),
    (28,4),
    (29,4),
    (30,4),
    (31,4),
    (32,4),
    (33,4),
    (34,4),
    (35,5),
    (36,5),
    (37,5),
    (38,5),
    (39,5),
    (40,5),
    (41,5),
    (42,5),
    (43,6),
    (44,6),
    (45,6),
    (46,6),
    (47,6),
    (48,6),
    (49,6),
    (50,6);

/*
#Classificacio
INSERT INTO classificacio (club_id, punts, lliga_id) VALUES
	(1, 40, 1),
	(8, 38, 1),
	(9, 33, 1),
	(4, 32, 1),
	(3, 30, 1),
	(10, 29, 1),
	(5, 24, 1),
	(7, 22, 1),
	(2, 20, 1),
	(6, 19, 1);
*/

-- Socis
INSERT INTO soci (nom, cognoms, data_naixement) VALUES
	('Juan', 'Pérez', '2000-01-01'),
	('María', 'González', '1998-02-14'),
	('Pedro', 'Rodríguez', '1997-03-21'),
	('Isabel', 'Martínez', '1999-04-30'),    
	('Javier', 'Sánchez', '1997-05-15'),
	('Laura', 'Ruiz', '2000-06-12'),
	('David', 'García', '1998-07-18'),
	('Ana', 'Jiménez', '1997-08-23'),
	('Daniel', 'Díaz', '1999-09-10'),
	('Lucía', 'Moreno', '1997-10-17'),
	('Alberto', 'Álvarez', '2000-11-20'),
	('Sara', 'Romero', '1998-12-25'),
	('Mario', 'Hernández', '1997-01-06'),
	('Rosa', 'Molina', '1999-02-01'),
	('Jorge', 'Morales', '1997-03-07');

-- Club i socis
INSERT INTO club_soci (id_club, id_soci) VALUES
	(2, 4),
	(5, 8),
	(7, 2),
	(9, 11),
	(4, 5),
	(1, 6),
	(6, 1),
	(10, 3),
	(3, 9),
	(8, 7),
	(5, 10),
	(2, 8),
	(7, 11),
	(1, 2),
	(9, 5),
	(4, 1),
	(6, 7),
	(10, 4),
	(3, 6);


UPDATE club SET titols = 96 WHERE id_club = 1;

UPDATE club SET titols = 16 WHERE id_club = 5;

UPDATE club SET titols = 93 WHERE id_club = 8;

UPDATE club SET titols = 22 WHERE id_club = 10;

UPDATE club SET club_rival_id = 4 WHERE id_club = 5;

UPDATE club SET club_rival_id = 5 WHERE id_club = 4;

UPDATE club SET club_rival_id = 8 WHERE id_club = 10;

UPDATE competicio SET any_fundacio = 1929 WHERE id_competicio = 1;


#1. Mostrar algunes columnes amb dos filtres on un intervé el valor NULL. (Volem mostrar els clubs creats a partir de 1905 i que tingin un rival directe).
SELECT nom, any_fundacio, pressupost, pais, club_rival_id 
FROM club 
WHERE (any_fundacio > 1905) 
	AND club_rival_id IS NOT NULL;

#2. Mostrar algunes columnes amb un filtre alfanumèric, on el valor d’una columna acabi amb uns caràcters en concret. (Volem mostrar clubs a partir de 1910 i que el seu nom acabi en 'na').
SELECT nom, any_fundacio, pais, entrenador_id, estadi_id 
FROM club 
WHERE any_fundacio > 1910 
	AND nom LIKE '%na';

#3. Mostrar algunes columnes amb un filtre entre dos valors. (Volem mostrar els clubs creats entre 1890 i 1910).
SELECT nom, any_fundacio, pais 
FROM club 
WHERE any_fundacio BETWEEN 1890 AND 1910;

#4. Mostrar totes columnes fent servir un filtre de LIKE. (Mostrem totes les columnes fent servir un filtre LIKE).
SELECT nom, any_fundacio, pais 
FROM club 
WHERE pais 
	LIKE 'Esp%';

#5. Mostrar informació resultat d’una funció d’agregació amb un filtre que combini AND i OR. (Mostrem el nombre de clubs fundats entre 1905 i 1915 o que tinguin rival directe fent servir una funcio d´agregacio, AND i OR).
SELECT COUNT(nom) AS Equips 
FROM club 
WHERE (any_fundacio > 1905 AND any_fundacio < 1915) 
	OR club_rival_id IS NOT NULL;

#6. Mostrar algunes columnes amb un filtre numèric i usa una funció d’agregació (Mostrem els titols maxims i minims registrats dins els valors limitats).
SELECT MIN(titols) AS Minim_titols, MAX(titols) AS Maxim_titols 
FROM club 
WHERE titols > 20 AND titols < 95;

#7. Mostrar totes columnes amb un subconjunt d’informació amb un filtre que faci servir una funció matemàtica.


#8. Mostrar algunes columnes amb tres filtres AND on un dels filtres faci servir una funció de caràcter (Mostrem els clubs en minuscules el quals es van fundar en any parell, tenen club rival i el seu nom acabi amb la lletra 'l').
SELECT LOWER(nom), any_fundacio, pais 
FROM club 
WHERE any_fundacio % 2 = 0 
	AND club_rival_id IS NOT NULL 
	AND nom LIKE '%l';

#9. Mostrar algunes columnes utilitzant funcions de caràcter amb un filtre alfanumèric. (Mostrem els clubs on el seu nom no es mes llarg de 14 caracters).
SELECT nom, any_fundacio, pais 
FROM club 
WHERE LENGTH(nom) < 14;

#10. Mostrar totes columnes aplicant un filtre i empra una funció de data. (Mostrem l´antiguetat dels clubs emprant una funcio de data).
SELECT nom, YEAR(CURTIME())-any_fundacio AS antiguetat 
FROM club;


#UF2P3: Explotació d´una BD

#Demanar estadi i club
SELECT c.nom AS club, e.nom AS estadi
FROM estadi e
	INNER JOIN club c ON e.id_estadi = c.estadi_id;

#Club + entrenador + president
SELECT c.nom AS club, CONCAT(p.nom, " ", p.cognom) AS president , CONCAT(e.nom, " ", e.cognom) AS entrenador
FROM club c
	INNER JOIN president p ON c.president_id = p.id_president
	INNER JOIN entrenador e ON c.entrenador_id = e.id_entrenador ORDER BY e.edat;

#Club i any de fundació
SELECT cl.nom, cl.any_fundacio
FROM competicio c
	INNER JOIN club_competicio cc ON c.id_competicio = cc.id_competicio
	INNER JOIN club cl ON cc.id_club = cl.id_club
	INNER JOIN entrenador e ON cl.entrenador_id = e.id_entrenador
WHERE e.nacionalitat = cl.pais ORDER BY cl.any_fundacio DESC;

#Clubs que tenen més titols totals que la mitjana de titols de tots els clubs sumats
SELECT cl.nom AS club, cl.titols
FROM club cl
WHERE cl.titols > (SELECT AVG(cl.titols) FROM club cl);


#Entrenadors de la mateixa nacionalitat de la lliga						
SELECT co.nom AS nomLliga, co.localitzacio AS paisLliga, cl.nom AS club, CONCAT(e.nom," ",e.cognom) AS nomEntrenador, e.nacionalitat AS nacionalitatEntrenador
FROM competicio co
	INNER JOIN club_competicio cc ON co.id_competicio = cc.id_competicio
	INNER JOIN club cl ON cc.id_club = cl.id_club
	RIGHT JOIN entrenador e ON cl.entrenador_id = e.id_entrenador
WHERE co.localitzacio = e.nacionalitat ORDER BY cl.nom;


#Una unió dels entrenadors que els seus presidents estàn al càrrec a partir del 2010 i els entrenadors que el seu euip té un pressupost més elevat que la mitja
(SELECT CONCAT(e.nom, " ", e.cognom) AS nom
FROM club cl
	INNER JOIN entrenador e ON cl.entrenador_id = e.id_entrenador
	INNER JOIN president p ON cl.president_id = p.id_president
WHERE p.inici_presidencia > 2010)
UNION 
(SELECT CONCAT(e.nom, " ", e.cognom) AS nom
FROM club cl
	INNER JOIN entrenador e ON cl.entrenador_id = e.id_entrenador
WHERE cl.pressupost > (SELECT AVG(pressupost) 
					  FROM club));

#Clubs amb capacitat d´estadi per sobre de la mitja i amb pressupost per sobre de la mitja
(SELECT cl.nom AS club, es.nom AS estadi, es.any_inauguracio, es.capacitat
FROM club cl
	INNER JOIN estadi es ON cl.estadi_id = es.id_estadi
WHERE es.capacitat > (SELECT AVG(capacitat) 
					  FROM estadi))
UNION
(
SELECT cl.nom AS club, es.nom AS estadi, es.any_inauguracio, es.capacitat
FROM estadi es 
	INNER JOIN club cl ON es.id_estadi = cl.estadi_id
WHERE es.any_inauguracio < (SELECT AVG(any_inauguracio) 
							FROM estadi));
                        


#Practica UF3P1
/*
CREATE USER 'admin_main' IDENTIFIED BY '1234'; #Volem un usuari administrador total, que tingui permisos a totes les taules de totes les bases de dades.

GRANT ALL PRIVILEGES
ON *.*
TO admin_main;
FLUSH PRIVILEGES;

CREATE USER admin IDENTIFIED BY '1234'; #Un usuari administrador més concret que només te permisos a la base de dades uf3_p3_emilio_nil.

GRANT ALL PRIVILEGES
ON uf3_p3_emilio_nil.*
TO admin;
FLUSH PRIVILEGES;


CREATE ROLE developer; #Aquest rol es l'encarregat de la infraestructura de la base de dades i te permisos per crear, modificar i eliminar taules.

GRANT CREATE, DROP, ALTER 
ON uf3_p3_emilio_nil.* 
TO developer;
FLUSH PRIVILEGES;


CREATE ROLE data_entrenador; #Volem un rol que tingui la responsabilitat de inserir les dades i actualitzar-les dels entrenadors, on no poden modificar el id un cop introduït per evitar errors futurs.

GRANT INSERT(nom, cognom, edat, nacionalitat), UPDATE(nom, cognom, edat, nacionalitat), SELECT
ON uf3_p3_emilio_nil.entrenador
TO data_entrenador;
FLUSH PRIVILEGES;


CREATE ROLE data_estadi; #Volem un rol on es tingui els permisos per donar de alta i actualitzar els estadis, i sense poder modificar el id un cop inserit.

GRANT INSERT(nom, capacitat, any_inauguracio, pais), UPDATE(nom, capacitat, any_inauguracio, pais), SELECT(id_estadi, nom, capacitat, any_inauguracio, pais)
ON uf3_p3_emilio_nil.estadi
TO data_estadi;
FLUSH PRIVILEGES;


CREATE ROLE data_club; #Volem un rol que tingui la capacitat de inserir i actualitzar les dades dels clubs, a més a més de les dades dels socis que pertanyen a diversos clubs.

GRANT INSERT(nom, any_fundacio, pressupost, titols, pais, entrenador_id, president_id, estadi_id), UPDATE(nom, any_fundacio, pressupost, titols, pais, entrenador_id, president_id, estadi_id), SELECT (id_club, nom, any_fundacio, pressupost, titols, pais, entrenador_id, president_id, estadi_id)
ON uf3_p3_emilio_nil.club
TO data_club;
FLUSH PRIVILEGES;

GRANT INSERT, UPDATE, SELECT
ON uf3_p3_emilio_nil.club_soci
TO data_club;
FLUSH PRIVILEGES;


CREATE ROLE data_soci; #En aquest rol donarem i mantindrem als socis que pertanyen a qualsevol club pero sense relacionar-lo amb qualsevol club.

GRANT INSERT(nom, cognoms, data_naixement, nacionalitat), UPDATE(nom, cognoms, data_naixement, nacionalitat), SELECT (id_soci, nom, cognoms, data_naixement, nacionalitat), DELETE
ON uf3_p3_emilio_nil.soci
TO data_soci;
FLUSH PRIVILEGES;


CREATE ROLE data_competicio; #Aqui tenim un rol que ocupa una responsabilitat superior en relacio a les competicions, aquest rol sera l'encarregat de donar d'alta les competicions inicialment, sense especificar el format, aquest rol te una responsabilitat major ja que pot modificar els id en cas de emergencia. 

GRANT INSERT(nom, participants, any_fundacio), UPDATE(id_competicio, nom, participants, any_fundacio), SELECT
ON TABLE uf3_p3_emilio_nil.competicio
TO data_competicio;
FLUSH PRIVILEGES;

CREATE ROLE data_lliga; #Aquest rol, es l'encarregat de registrar les lligues un cop estiguin donades d'alta com competicions, te permisos per registar la lliga i la seva classificació, a més a més te accés per decidir quins son els rivals directes dels clubs segons la situacio de la lliga.

GRANT INSERT, UPDATE(divisio, pais), SELECT
ON uf3_p3_emilio_nil.lliga
TO data_lliga;
FLUSH PRIVILEGES;

GRANT INSERT(posicio, club_id, lliga_id), UPDATE(posicio), SELECT(posicio, club_id, lliga_id) #En aquest cas no en importa l'id de la classificacio, si no el id de la lliga i la resta de dades.
ON uf3_p3_emilio_nil.classificacio
TO data_lliga;
FLUSH PRIVILEGES;

GRANT INSERT(club_rival_id), UPDATE(club_rival_id)
ON TABLE uf3_p3_emilio_nil.club
TO data_lliga;
FLUSH PRIVILEGES;

CREATE ROLE data_torneig; #Aquest rol es l'encarregat de registrar les competicions que son tornejos aixi com actualitzar les dades.

GRANT INSERT(organitzador, localitzacio), UPDATE(organitzador, localitzacio), SELECT
ON uf3_p3_emilio_nil.torneig
TO data_torneig;
FLUSH PRIVILEGES;

#Creem els usuaris que utilitzaran els rols per mantenir i gestionar la base de dades.

CREATE USER 'dev_emilio_fernandez' IDENTIFIED BY '1234';
CREATE USER 'nil_arilla' IDENTIFIED BY '1234';
CREATE USER 'emilio_fernandez' IDENTIFIED BY '1234';


#Afegim els usuaris a mode d'exemple als rols corresponents
GRANT data_competicio
TO 'nil_arilla'; 

GRANT data_lliga 
TO 'emilio_fernandez';

GRANT data_club
TO 'emilio_fernandez';

GRANT developer
TO 'dev_emilio_fernandez';

GRANT data_estadi
TO 'nil_arilla';

*/


