CREATE SEQUENCE expenses_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

CREATE TABLE expenses (
    name character(255),
    price double precision,
    created_at timestamp without time zone,
    id integer NOT NULL,
    chat_id character(255)
);
ALTER TABLE ONLY expenses ALTER COLUMN id SET DEFAULT nextval('expenses_id_seq'::regclass);
