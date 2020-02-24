--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.10
-- Dumped by pg_dump version 9.5.10

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: fminames; Type: DATABASE; Schema: -; Owner: fminames_user
--

CREATE DATABASE fminames WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.utf8' LC_CTYPE = 'en_US.utf8';


ALTER DATABASE fminames OWNER TO fminames_user;

\connect fminames

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: topology; Type: SCHEMA; Schema: -; Owner: fminames_user
--

CREATE SCHEMA topology;


ALTER SCHEMA topology OWNER TO fminames_user;

--
-- Name: SCHEMA topology; Type: COMMENT; Schema: -; Owner: fminames_user
--

COMMENT ON SCHEMA topology IS 'PostGIS Topology schema';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry, geography, and raster spatial types and functions';


--
-- Name: postgis_topology; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS postgis_topology WITH SCHEMA topology;


--
-- Name: EXTENSION postgis_topology; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis_topology IS 'PostGIS topology spatial types and functions';


SET search_path = public, pg_catalog;

--
-- Name: source_enum; Type: TYPE; Schema: public; Owner: fminames_user
--

CREATE TYPE source_enum AS ENUM (
    'geonames.org',
    'fmi',
    'fmihav'
);


ALTER TYPE source_enum OWNER TO fminames_user;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alternate_geonames; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE alternate_geonames (
    id integer NOT NULL,
    source source_enum NOT NULL,
    geonames_id integer NOT NULL,
    language character varying(100) NOT NULL,
    name character varying(200) NOT NULL,
    preferred boolean DEFAULT false NOT NULL,
    short boolean DEFAULT false NOT NULL,
    colloquial boolean DEFAULT false NOT NULL,
    historic boolean DEFAULT false NOT NULL,
    priority integer DEFAULT 50 NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    last_modified timestamp without time zone DEFAULT now()
);


ALTER TABLE alternate_geonames OWNER TO fminames_user;

--
-- Name: alternate_municipalities; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE alternate_municipalities (
    id integer NOT NULL,
    municipalities_id integer NOT NULL,
    name character varying(200) NOT NULL,
    language character varying(10)
);


ALTER TABLE alternate_municipalities OWNER TO fminames_user;

--
-- Name: countries; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE countries (
    iso2 character(2) NOT NULL,
    iso3 character(3) NOT NULL,
    iso_numeric integer,
    fips character(2),
    name character varying(50) NOT NULL,
    capital character varying(100),
    areainsqkm double precision,
    population integer,
    continent character(2),
    tld character(4),
    currency_code character(3),
    currency_name character varying(20),
    phone character varying(20),
    postal_code_fmt character varying(60),
    postal_code_ngx character varying(200),
    languages character varying(100),
    geonames_id integer,
    neighbors character varying(75)
);


ALTER TABLE countries OWNER TO fminames_user;

--
-- Name: features; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE features (
    code character varying(8) NOT NULL,
    shortdesc character varying(50) DEFAULT ''::character varying NOT NULL,
    longdesc character varying(255) DEFAULT ''::character varying NOT NULL,
    class character(1)
);


ALTER TABLE features OWNER TO fminames_user;

--
-- Name: geonames; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE geonames (
    id integer NOT NULL,
    name character varying(200) NOT NULL,
    ansiname character varying(200) DEFAULT ''::character varying,
    lat double precision NOT NULL,
    lon double precision NOT NULL,
    class character(1) DEFAULT NULL::bpchar,
    features_code character varying(10) DEFAULT NULL::character varying,
    countries_iso2 character varying(2) DEFAULT NULL::character varying,
    cc2 character varying(60),
    admin1 character varying(20) DEFAULT NULL::character varying,
    admin2 character varying(80) DEFAULT NULL::character varying,
    admin3 character varying(20) DEFAULT NULL::character varying,
    admin4 character varying(20) DEFAULT NULL::character varying,
    population bigint DEFAULT 0,
    elevation integer,
    dem integer,
    timezone character varying(40) DEFAULT NULL::character varying,
    modified date DEFAULT ('now'::text)::date NOT NULL,
    municipalities_id integer DEFAULT 0 NOT NULL,
    priority integer DEFAULT 50 NOT NULL,
    locked boolean DEFAULT false NOT NULL,
    the_geom geometry NOT NULL,
    the_geog geography NOT NULL,
    last_modified timestamp without time zone,
    landcover integer
);


ALTER TABLE geonames OWNER TO fminames_user;

--
-- Name: keywords; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE keywords (
    keyword character varying(50) NOT NULL,
    comment character varying(200) DEFAULT ''::character varying,
    languages character varying(200) DEFAULT ''::character varying,
    autocomplete boolean DEFAULT false NOT NULL
);


ALTER TABLE keywords OWNER TO fminames_user;

--
-- Name: keywords_has_geonames; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE keywords_has_geonames (
    keyword character varying(50) NOT NULL,
    geonames_id integer NOT NULL,
    comment character varying(200) DEFAULT ''::character varying,
    name character varying(200) DEFAULT ''::character varying,
    last_modified timestamp without time zone DEFAULT now()
);


ALTER TABLE keywords_has_geonames OWNER TO fminames_user;

--
-- Name: languages; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE languages (
    iso_639_3 character(3) NOT NULL,
    iso_639_2 character(3) DEFAULT NULL::bpchar,
    iso_639_1 character(2) DEFAULT NULL::bpchar,
    name character varying(100) NOT NULL
);


ALTER TABLE languages OWNER TO fminames_user;

--
-- Name: municipalities; Type: TABLE; Schema: public; Owner: fminames_user
--

CREATE TABLE municipalities (
    id integer NOT NULL,
    countries_iso2 character(2) NOT NULL,
    name character varying(200) NOT NULL,
    code integer
);


ALTER TABLE municipalities OWNER TO fminames_user;

--
-- Name: alternate_geonames_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY alternate_geonames
    ADD CONSTRAINT alternate_geonames_pkey PRIMARY KEY (id, source);


--
-- Name: alternate_municipalities_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY alternate_municipalities
    ADD CONSTRAINT alternate_municipalities_pkey PRIMARY KEY (id);


--
-- Name: countries_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY countries
    ADD CONSTRAINT countries_pkey PRIMARY KEY (iso2);


--
-- Name: features_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY features
    ADD CONSTRAINT features_pkey PRIMARY KEY (code);


--
-- Name: keywords_has_geonames_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY keywords_has_geonames
    ADD CONSTRAINT keywords_has_geonames_pkey PRIMARY KEY (keyword, geonames_id);


--
-- Name: keywords_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY keywords
    ADD CONSTRAINT keywords_pkey PRIMARY KEY (keyword);


--
-- Name: languages_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY languages
    ADD CONSTRAINT languages_pkey PRIMARY KEY (iso_639_3);


--
-- Name: municipalities_pkey; Type: CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY municipalities
    ADD CONSTRAINT municipalities_pkey PRIMARY KEY (id);


--
-- Name: idx_alternate_geonames_last_modified; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_alternate_geonames_last_modified ON alternate_geonames USING btree (last_modified);


--
-- Name: idx_alternategeoid; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_alternategeoid ON alternate_geonames USING btree (geonames_id);


--
-- Name: idx_alternatename; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_alternatename ON alternate_geonames USING btree (name);


--
-- Name: idx_geonamecountry; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_geonamecountry ON geonames USING btree (countries_iso2);


--
-- Name: idx_geonamefeature; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_geonamefeature ON geonames USING btree (features_code);


--
-- Name: idx_gistgeog; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_gistgeog ON geonames USING gist (the_geog);


--
-- Name: idx_gistgeom; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_gistgeom ON geonames USING gist (the_geom);

ALTER TABLE geonames CLUSTER ON idx_gistgeom;


--
-- Name: idx_keywords_has_geonames_last_modified; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_keywords_has_geonames_last_modified ON keywords_has_geonames USING btree (last_modified);


--
-- Name: idx_last_modified; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_last_modified ON geonames USING btree (last_modified);


--
-- Name: idx_loweralternatename; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_loweralternatename ON alternate_geonames USING btree (lower((name)::text));


--
-- Name: idx_lowername; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_lowername ON geonames USING btree (lower((name)::text));


--
-- Name: idx_name; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_name ON geonames USING btree (name);


--
-- Name: idx_population; Type: INDEX; Schema: public; Owner: fminames_user
--

CREATE INDEX idx_population ON geonames USING btree (population);


--
-- Name: fk_keywords_has_geonames_keywords; Type: FK CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY keywords_has_geonames
    ADD CONSTRAINT fk_keywords_has_geonames_keywords FOREIGN KEY (keyword) REFERENCES keywords(keyword);


--
-- Name: fk_municipalities_iso2; Type: FK CONSTRAINT; Schema: public; Owner: fminames_user
--

ALTER TABLE ONLY municipalities
    ADD CONSTRAINT fk_municipalities_iso2 FOREIGN KEY (countries_iso2) REFERENCES countries(iso2);


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- Name: alternate_geonames; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE alternate_geonames FROM PUBLIC;
REVOKE ALL ON TABLE alternate_geonames FROM fminames_user;
GRANT ALL ON TABLE alternate_geonames TO fminames_user;


--
-- Name: alternate_municipalities; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE alternate_municipalities FROM PUBLIC;
REVOKE ALL ON TABLE alternate_municipalities FROM fminames_user;
GRANT ALL ON TABLE alternate_municipalities TO fminames_user;


--
-- Name: countries; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE countries FROM PUBLIC;
REVOKE ALL ON TABLE countries FROM fminames_user;
GRANT ALL ON TABLE countries TO fminames_user;


--
-- Name: features; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE features FROM PUBLIC;
REVOKE ALL ON TABLE features FROM fminames_user;
GRANT ALL ON TABLE features TO fminames_user;


--
-- Name: geonames; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE geonames FROM PUBLIC;
REVOKE ALL ON TABLE geonames FROM fminames_user;
GRANT ALL ON TABLE geonames TO fminames_user;


--
-- Name: keywords; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE keywords FROM PUBLIC;
REVOKE ALL ON TABLE keywords FROM fminames_user;
GRANT ALL ON TABLE keywords TO fminames_user;


--
-- Name: keywords_has_geonames; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE keywords_has_geonames FROM PUBLIC;
REVOKE ALL ON TABLE keywords_has_geonames FROM fminames_user;
GRANT ALL ON TABLE keywords_has_geonames TO fminames_user;


--
-- Name: languages; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE languages FROM PUBLIC;
REVOKE ALL ON TABLE languages FROM fminames_user;
GRANT ALL ON TABLE languages TO fminames_user;


--
-- Name: municipalities; Type: ACL; Schema: public; Owner: fminames_user
--

REVOKE ALL ON TABLE municipalities FROM PUBLIC;
REVOKE ALL ON TABLE municipalities FROM fminames_user;
GRANT ALL ON TABLE municipalities TO fminames_user;


--
-- PostgreSQL database dump complete
--

