



-- Création des tables avec colonnes fictives
CREATE TABLE accident (
    num_acc SERIAL PRIMARY KEY,
    description VARCHAR(255),
    date_acc DATE
);

CREATE TABLE vehicule (
    num_vehicule SERIAL PRIMARY KEY,
    type_vehicule VARCHAR(50),
    num_acc INT
);

CREATE TABLE usager (
    num_usager SERIAL PRIMARY KEY,
    nom VARCHAR(100),
    prenom VARCHAR(100),
    num_acc INT
);

CREATE TABLE lieux (
    num_lieu SERIAL PRIMARY KEY,
    ville VARCHAR(100),
    rue VARCHAR(100),
    num_acc INT
);

CREATE TABLE date_time (
    num_entry SERIAL PRIMARY KEY,
    date_heure TIMESTAMP,
    num_acc INT
);

-- Ajout des clés étrangères
ALTER TABLE vehicule
ADD CONSTRAINT fk_accident FOREIGN KEY (num_acc) REFERENCES accident(num_acc);

ALTER TABLE usager
ADD CONSTRAINT fk_accident_usager FOREIGN KEY (num_acc) REFERENCES accident(num_acc);

ALTER TABLE lieux
ADD CONSTRAINT fk_accident_lieux FOREIGN KEY (num_acc) REFERENCES accident(num_acc);

ALTER TABLE date_time
ADD CONSTRAINT fk_accident_date FOREIGN KEY (num_acc) REFERENCES accident(num_acc);
