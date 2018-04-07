--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.4
-- Dumped by pg_dump version 9.6.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: btree_gin; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS btree_gin WITH SCHEMA public;


--
-- Name: EXTENSION btree_gin; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION btree_gin IS 'support for indexing common datatypes in GIN';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA public;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track execution statistics of all SQL statements executed';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: update_keys_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_keys_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_keys_key_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_keys_key_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_key := to_tsvector('pg_catalog.simple', coalesce(new.key::TEXT, '')); RETURN new; END $$;


--
-- Name: update_licenses_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_licenses_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_licenses_key_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_licenses_key_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_key := to_tsvector('pg_catalog.simple', coalesce(new.key::TEXT, '')); RETURN new; END $$;


--
-- Name: update_licenses_metadata_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_licenses_metadata_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_metadata := to_tsvector('pg_catalog.simple', coalesce(new.metadata::TEXT, '')); RETURN new; END $$;


--
-- Name: update_machines_fingerprint_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_machines_fingerprint_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_fingerprint := to_tsvector('pg_catalog.simple', coalesce(new.fingerprint::TEXT, '')); RETURN new; END $$;


--
-- Name: update_machines_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_machines_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_machines_metadata_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_machines_metadata_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_metadata := to_tsvector('pg_catalog.simple', coalesce(new.metadata::TEXT, '')); RETURN new; END $$;


--
-- Name: update_policies_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_policies_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_policies_metadata_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_policies_metadata_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_metadata := to_tsvector('pg_catalog.simple', coalesce(new.metadata::TEXT, '')); RETURN new; END $$;


--
-- Name: update_policies_name_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_policies_name_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_name := to_tsvector('pg_catalog.simple', coalesce(new.name::TEXT, '')); RETURN new; END $$;


--
-- Name: update_products_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_products_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_products_metadata_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_products_metadata_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_metadata := to_tsvector('pg_catalog.simple', coalesce(new.metadata::TEXT, '')); RETURN new; END $$;


--
-- Name: update_products_name_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_products_name_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_name := to_tsvector('pg_catalog.simple', coalesce(new.name::TEXT, '')); RETURN new; END $$;


--
-- Name: update_users_email_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_email_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_email := to_tsvector('pg_catalog.simple', coalesce(new.email::TEXT, '')); RETURN new; END $$;


--
-- Name: update_users_first_name_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_first_name_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_first_name := to_tsvector('pg_catalog.simple', coalesce(new.first_name::TEXT, '')); RETURN new; END $$;


--
-- Name: update_users_id_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_id_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_id := to_tsvector('pg_catalog.simple', coalesce(new.id::TEXT, '')); RETURN new; END $$;


--
-- Name: update_users_last_name_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_last_name_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_last_name := to_tsvector('pg_catalog.simple', coalesce(new.last_name::TEXT, '')); RETURN new; END $$;


--
-- Name: update_users_metadata_tsvector(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION update_users_metadata_tsvector() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ BEGIN new.tsv_metadata := to_tsvector('pg_catalog.simple', coalesce(new.metadata::TEXT, '')); RETURN new; END $$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: accounts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE accounts (
    name character varying,
    slug character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    plan_id uuid,
    protected boolean DEFAULT false,
    public_key text,
    private_key text
);


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: billings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE billings (
    customer_id character varying,
    subscription_status character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    subscription_id character varying,
    subscription_period_start timestamp without time zone,
    subscription_period_end timestamp without time zone,
    card_expiry timestamp without time zone,
    card_brand character varying,
    card_last4 character varying,
    state character varying,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid
);


--
-- Name: keys; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE keys (
    key character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    policy_id uuid,
    account_id uuid,
    tsv_id tsvector,
    tsv_key tsvector
);


--
-- Name: licenses; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE licenses (
    key character varying,
    expiry timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    metadata jsonb,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    user_id uuid,
    policy_id uuid,
    account_id uuid,
    suspended boolean DEFAULT false,
    last_check_in_at timestamp without time zone,
    last_expiration_event_sent_at timestamp without time zone,
    last_check_in_event_sent_at timestamp without time zone,
    last_expiring_soon_event_sent_at timestamp without time zone,
    last_check_in_soon_event_sent_at timestamp without time zone,
    uses integer DEFAULT 0,
    tsv_id tsvector,
    tsv_key tsvector,
    tsv_metadata tsvector
);


--
-- Name: machines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE machines (
    fingerprint character varying,
    ip character varying,
    hostname character varying,
    platform character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying,
    metadata jsonb,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    license_id uuid,
    tsv_id tsvector,
    tsv_fingerprint tsvector,
    tsv_metadata tsvector
);


--
-- Name: metrics; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE metrics (
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    metric character varying,
    data jsonb,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: plans; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE plans (
    name character varying,
    price integer,
    max_users integer,
    max_policies integer,
    max_licenses integer,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    max_products integer,
    plan_id character varying,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    private boolean DEFAULT false,
    trial_duration integer,
    max_reqs integer,
    max_admins integer
);


--
-- Name: policies; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE policies (
    name character varying,
    duration integer,
    strict boolean DEFAULT false,
    floating boolean DEFAULT false,
    use_pool boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    lock_version integer DEFAULT 0 NOT NULL,
    max_machines integer,
    encrypted boolean DEFAULT false,
    protected boolean,
    metadata jsonb,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    product_id uuid,
    account_id uuid,
    check_in_interval character varying,
    check_in_interval_count integer,
    require_check_in boolean DEFAULT false,
    require_product_scope boolean DEFAULT false,
    require_policy_scope boolean DEFAULT false,
    require_machine_scope boolean DEFAULT false,
    require_fingerprint_scope boolean DEFAULT false,
    concurrent boolean DEFAULT true,
    max_uses integer,
    tsv_id tsvector,
    tsv_name tsvector,
    tsv_metadata tsvector
);


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE products (
    name character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    platforms jsonb,
    metadata jsonb,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    url character varying,
    tsv_id tsvector,
    tsv_name tsvector,
    tsv_metadata tsvector
);


--
-- Name: receipts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE receipts (
    invoice_id character varying,
    amount integer,
    paid boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    billing_id uuid
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE roles (
    name character varying,
    resource_type character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    resource_id uuid
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE schema_migrations (
    version character varying NOT NULL
);


--
-- Name: tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE tokens (
    digest character varying,
    bearer_type character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    expiry timestamp without time zone,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    bearer_id uuid,
    account_id uuid
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE users (
    email character varying,
    password_digest character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    password_reset_token character varying,
    password_reset_sent_at timestamp without time zone,
    metadata jsonb,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    first_name character varying,
    last_name character varying,
    tsv_id tsvector,
    tsv_email tsvector,
    tsv_first_name tsvector,
    tsv_last_name tsvector,
    tsv_metadata tsvector
);


--
-- Name: webhook_endpoints; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE webhook_endpoints (
    url character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid
);


--
-- Name: webhook_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE webhook_events (
    payload text,
    jid character varying,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    endpoint character varying,
    id uuid DEFAULT uuid_generate_v4() NOT NULL,
    account_id uuid,
    idempotency_token character varying,
    event character varying
);


--
-- Name: accounts accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY accounts
    ADD CONSTRAINT accounts_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: billings billings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY billings
    ADD CONSTRAINT billings_pkey PRIMARY KEY (id);


--
-- Name: keys keys_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY keys
    ADD CONSTRAINT keys_pkey PRIMARY KEY (id);


--
-- Name: licenses licenses_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY licenses
    ADD CONSTRAINT licenses_pkey PRIMARY KEY (id);


--
-- Name: machines machines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY machines
    ADD CONSTRAINT machines_pkey PRIMARY KEY (id);


--
-- Name: metrics metrics_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY metrics
    ADD CONSTRAINT metrics_pkey PRIMARY KEY (id);


--
-- Name: plans plans_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY plans
    ADD CONSTRAINT plans_pkey PRIMARY KEY (id);


--
-- Name: policies policies_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY policies
    ADD CONSTRAINT policies_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: receipts receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY receipts
    ADD CONSTRAINT receipts_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webhook_endpoints webhook_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY webhook_endpoints
    ADD CONSTRAINT webhook_endpoints_pkey PRIMARY KEY (id);


--
-- Name: webhook_events webhook_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY webhook_events
    ADD CONSTRAINT webhook_events_pkey PRIMARY KEY (id);


--
-- Name: index_accounts_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_id_and_created_at ON accounts USING btree (id, created_at);


--
-- Name: index_accounts_on_plan_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_accounts_on_plan_id_and_created_at ON accounts USING btree (plan_id, created_at);


--
-- Name: index_accounts_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_slug ON accounts USING btree (slug);


--
-- Name: index_accounts_on_slug_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_accounts_on_slug_and_created_at ON accounts USING btree (slug, created_at);


--
-- Name: index_billings_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_billings_on_account_id_and_created_at ON billings USING btree (account_id, created_at);


--
-- Name: index_billings_on_customer_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_billings_on_customer_id_and_created_at ON billings USING btree (customer_id, created_at);


--
-- Name: index_billings_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_billings_on_id_and_created_at ON billings USING btree (id, created_at);


--
-- Name: index_billings_on_subscription_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_billings_on_subscription_id_and_created_at ON billings USING btree (subscription_id, created_at);


--
-- Name: index_keys_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_account_id_and_created_at ON keys USING btree (account_id, created_at);


--
-- Name: index_keys_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_keys_on_id_and_created_at_and_account_id ON keys USING btree (id, created_at, account_id);


--
-- Name: index_keys_on_policy_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_policy_id_and_created_at ON keys USING btree (policy_id, created_at);


--
-- Name: index_keys_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_tsv_id ON keys USING gin (tsv_id);


--
-- Name: index_keys_on_tsv_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_keys_on_tsv_key ON keys USING gin (tsv_key);


--
-- Name: index_licenses_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_account_id_and_created_at ON licenses USING btree (account_id, created_at);


--
-- Name: index_licenses_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_licenses_on_id_and_created_at_and_account_id ON licenses USING btree (id, created_at, account_id);


--
-- Name: index_licenses_on_key_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_key_and_created_at_and_account_id ON licenses USING btree (key, created_at, account_id);


--
-- Name: index_licenses_on_policy_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_policy_id_and_created_at ON licenses USING btree (policy_id, created_at);


--
-- Name: index_licenses_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_tsv_id ON licenses USING gin (tsv_id);


--
-- Name: index_licenses_on_tsv_key; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_tsv_key ON licenses USING gin (tsv_key);


--
-- Name: index_licenses_on_tsv_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_tsv_metadata ON licenses USING gin (tsv_metadata);


--
-- Name: index_licenses_on_user_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_licenses_on_user_id_and_created_at ON licenses USING btree (user_id, created_at);


--
-- Name: index_machines_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_account_id_and_created_at ON machines USING btree (account_id, created_at);


--
-- Name: index_machines_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_machines_on_id_and_created_at_and_account_id ON machines USING btree (id, created_at, account_id);


--
-- Name: index_machines_on_license_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_license_id_and_created_at ON machines USING btree (license_id, created_at);


--
-- Name: index_machines_on_tsv_fingerprint; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_tsv_fingerprint ON machines USING gin (tsv_fingerprint);


--
-- Name: index_machines_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_tsv_id ON machines USING gin (tsv_id);


--
-- Name: index_machines_on_tsv_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_machines_on_tsv_metadata ON machines USING gin (tsv_metadata);


--
-- Name: index_metrics_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_metrics_on_account_id_and_created_at ON metrics USING btree (account_id, created_at);


--
-- Name: index_metrics_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_metrics_on_id_and_created_at ON metrics USING btree (id, created_at);


--
-- Name: index_plans_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_plans_on_id_and_created_at ON plans USING btree (id, created_at);


--
-- Name: index_plans_on_plan_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_plans_on_plan_id_and_created_at ON plans USING btree (plan_id, created_at);


--
-- Name: index_policies_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_policies_on_account_id_and_created_at ON policies USING btree (account_id, created_at);


--
-- Name: index_policies_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_policies_on_id_and_created_at_and_account_id ON policies USING btree (id, created_at, account_id);


--
-- Name: index_policies_on_product_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_policies_on_product_id_and_created_at ON policies USING btree (product_id, created_at);


--
-- Name: index_policies_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_policies_on_tsv_id ON policies USING gin (tsv_id);


--
-- Name: index_policies_on_tsv_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_policies_on_tsv_metadata ON policies USING gin (tsv_metadata);


--
-- Name: index_policies_on_tsv_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_policies_on_tsv_name ON policies USING gin (tsv_name);


--
-- Name: index_products_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_account_id_and_created_at ON products USING btree (account_id, created_at);


--
-- Name: index_products_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_products_on_id_and_created_at_and_account_id ON products USING btree (id, created_at, account_id);


--
-- Name: index_products_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tsv_id ON products USING gin (tsv_id);


--
-- Name: index_products_on_tsv_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tsv_metadata ON products USING gin (tsv_metadata);


--
-- Name: index_products_on_tsv_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_products_on_tsv_name ON products USING gin (tsv_name);


--
-- Name: index_receipts_on_billing_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_receipts_on_billing_id_and_created_at ON receipts USING btree (billing_id, created_at);


--
-- Name: index_receipts_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_receipts_on_id_and_created_at ON receipts USING btree (id, created_at);


--
-- Name: index_roles_on_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_roles_on_id_and_created_at ON roles USING btree (id, created_at);


--
-- Name: index_roles_on_name_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_name_and_created_at ON roles USING btree (name, created_at);


--
-- Name: index_roles_on_resource_id_and_resource_type_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_on_resource_id_and_resource_type_and_created_at ON roles USING btree (resource_id, resource_type, created_at);


--
-- Name: index_tokens_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_account_id_and_created_at ON tokens USING btree (account_id, created_at);


--
-- Name: index_tokens_on_bearer_id_and_bearer_type_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_tokens_on_bearer_id_and_bearer_type_and_created_at ON tokens USING btree (bearer_id, bearer_type, created_at);


--
-- Name: index_tokens_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tokens_on_id_and_created_at_and_account_id ON tokens USING btree (id, created_at, account_id);


--
-- Name: index_users_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_account_id_and_created_at ON users USING btree (account_id, created_at);


--
-- Name: index_users_on_email_and_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_email_and_account_id_and_created_at ON users USING btree (email, account_id, created_at);


--
-- Name: index_users_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_id_and_created_at_and_account_id ON users USING btree (id, created_at, account_id);


--
-- Name: index_users_on_tsv_email; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_tsv_email ON users USING gin (tsv_email);


--
-- Name: index_users_on_tsv_first_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_tsv_first_name ON users USING gin (tsv_first_name);


--
-- Name: index_users_on_tsv_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_tsv_id ON users USING gin (tsv_id);


--
-- Name: index_users_on_tsv_last_name; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_tsv_last_name ON users USING gin (tsv_last_name);


--
-- Name: index_users_on_tsv_metadata; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_users_on_tsv_metadata ON users USING gin (tsv_metadata);


--
-- Name: index_webhook_endpoints_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_endpoints_on_account_id_and_created_at ON webhook_endpoints USING btree (account_id, created_at);


--
-- Name: index_webhook_endpoints_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webhook_endpoints_on_id_and_created_at_and_account_id ON webhook_endpoints USING btree (id, created_at, account_id);


--
-- Name: index_webhook_events_on_account_id_and_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_events_on_account_id_and_created_at ON webhook_events USING btree (account_id, created_at);


--
-- Name: index_webhook_events_on_id_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_webhook_events_on_id_and_created_at_and_account_id ON webhook_events USING btree (id, created_at, account_id);


--
-- Name: index_webhook_events_on_idempotency_token; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_events_on_idempotency_token ON webhook_events USING btree (idempotency_token);


--
-- Name: index_webhook_events_on_jid_and_created_at_and_account_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_webhook_events_on_jid_and_created_at_and_account_id ON webhook_events USING btree (jid, created_at, account_id);


--
-- Name: keys tsvector_trigger_keys_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_keys_id BEFORE INSERT OR UPDATE ON keys FOR EACH ROW EXECUTE PROCEDURE update_keys_id_tsvector();


--
-- Name: keys tsvector_trigger_keys_key; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_keys_key BEFORE INSERT OR UPDATE ON keys FOR EACH ROW EXECUTE PROCEDURE update_keys_key_tsvector();


--
-- Name: licenses tsvector_trigger_licenses_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_licenses_id BEFORE INSERT OR UPDATE ON licenses FOR EACH ROW EXECUTE PROCEDURE update_licenses_id_tsvector();


--
-- Name: licenses tsvector_trigger_licenses_key; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_licenses_key BEFORE INSERT OR UPDATE ON licenses FOR EACH ROW EXECUTE PROCEDURE update_licenses_key_tsvector();


--
-- Name: licenses tsvector_trigger_licenses_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_licenses_metadata BEFORE INSERT OR UPDATE ON licenses FOR EACH ROW EXECUTE PROCEDURE update_licenses_metadata_tsvector();


--
-- Name: machines tsvector_trigger_machines_fingerprint; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_machines_fingerprint BEFORE INSERT OR UPDATE ON machines FOR EACH ROW EXECUTE PROCEDURE update_machines_fingerprint_tsvector();


--
-- Name: machines tsvector_trigger_machines_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_machines_id BEFORE INSERT OR UPDATE ON machines FOR EACH ROW EXECUTE PROCEDURE update_machines_id_tsvector();


--
-- Name: machines tsvector_trigger_machines_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_machines_metadata BEFORE INSERT OR UPDATE ON machines FOR EACH ROW EXECUTE PROCEDURE update_machines_metadata_tsvector();


--
-- Name: policies tsvector_trigger_policies_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_policies_id BEFORE INSERT OR UPDATE ON policies FOR EACH ROW EXECUTE PROCEDURE update_policies_id_tsvector();


--
-- Name: policies tsvector_trigger_policies_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_policies_metadata BEFORE INSERT OR UPDATE ON policies FOR EACH ROW EXECUTE PROCEDURE update_policies_metadata_tsvector();


--
-- Name: policies tsvector_trigger_policies_name; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_policies_name BEFORE INSERT OR UPDATE ON policies FOR EACH ROW EXECUTE PROCEDURE update_policies_name_tsvector();


--
-- Name: products tsvector_trigger_products_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_products_id BEFORE INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE update_products_id_tsvector();


--
-- Name: products tsvector_trigger_products_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_products_metadata BEFORE INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE update_products_metadata_tsvector();


--
-- Name: products tsvector_trigger_products_name; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_products_name BEFORE INSERT OR UPDATE ON products FOR EACH ROW EXECUTE PROCEDURE update_products_name_tsvector();


--
-- Name: users tsvector_trigger_users_email; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_users_email BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users_email_tsvector();


--
-- Name: users tsvector_trigger_users_first_name; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_users_first_name BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users_first_name_tsvector();


--
-- Name: users tsvector_trigger_users_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_users_id BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users_id_tsvector();


--
-- Name: users tsvector_trigger_users_last_name; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_users_last_name BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users_last_name_tsvector();


--
-- Name: users tsvector_trigger_users_metadata; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvector_trigger_users_metadata BEFORE INSERT OR UPDATE ON users FOR EACH ROW EXECUTE PROCEDURE update_users_metadata_tsvector();


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO schema_migrations (version) VALUES
('20160521203749'),
('20160521203755'),
('20160521203951'),
('20160521205600'),
('20160523033249'),
('20160523033613'),
('20160523033950'),
('20160523035909'),
('20160523040214'),
('20160523141521'),
('20160523144935'),
('20160530024204'),
('20160530033523'),
('20160530040830'),
('20160530044342'),
('20160530050836'),
('20160530051016'),
('20160530051022'),
('20160601022240'),
('20160601023618'),
('20160601023633'),
('20160601145430'),
('20160604225908'),
('20160605002506'),
('20160605003217'),
('20160605003223'),
('20160605003647'),
('20160605004207'),
('20160606164154'),
('20160606171944'),
('20160606173406'),
('20160606200838'),
('20160606200844'),
('20160608001847'),
('20160610015703'),
('20160610225535'),
('20160611211620'),
('20160611212320'),
('20160613172328'),
('20160624200649'),
('20160624222452'),
('20160624225008'),
('20160625170213'),
('20160625172108'),
('20160823140738'),
('20160823141837'),
('20160823142134'),
('20160823144125'),
('20160823150843'),
('20160823161731'),
('20160823162151'),
('20160823170245'),
('20160823171439'),
('20160823222717'),
('20160824140927'),
('20160922154405'),
('20160927003417'),
('20160927225336'),
('20160929143658'),
('20160930194911'),
('20160930210412'),
('20161002141658'),
('20161003231717'),
('20161004141729'),
('20161004173254'),
('20161004214055'),
('20161014211305'),
('20161016210357'),
('20161019163352'),
('20161025160227'),
('20161025160259'),
('20161025161721'),
('20161025164655'),
('20161025172023'),
('20161025195849'),
('20161109161426'),
('20161109161432'),
('20161109161438'),
('20161109161521'),
('20161109162223'),
('20161109175721'),
('20161110144731'),
('20161110200754'),
('20161113062255'),
('20161116173514'),
('20161118202415'),
('20161118203800'),
('20161122225420'),
('20161128221435'),
('20161129163232'),
('20161129180943'),
('20161212161355'),
('20161212161422'),
('20161216192024'),
('20161216192133'),
('20161216192309'),
('20161216193828'),
('20161216194000'),
('20161216194125'),
('20161216194507'),
('20161216221525'),
('20161229170420'),
('20161230174909'),
('20170103225920'),
('20170104163650'),
('20170105161602'),
('20170108191700'),
('20170123141516'),
('20170207171359'),
('20170207230359'),
('20170207233326'),
('20170220152847'),
('20170220160538'),
('20170314014254'),
('20170314030836'),
('20170425195815'),
('20170502003137'),
('20170509144501'),
('20170520205233'),
('20170520205238'),
('20170530221041'),
('20170531143646'),
('20170601145115'),
('20170623141428'),
('20170726144233'),
('20171013161238'),
('20171016142634'),
('20171025153644'),
('20171025174051'),
('20171107203246'),
('20171107210504'),
('20171109155034'),
('20171109165056'),
('20171213213747'),
('20171227201645'),
('20180102202231'),
('20180309035004'),
('20180309035015'),
('20180318024935'),
('20180406189154'),
('20180406191144');


