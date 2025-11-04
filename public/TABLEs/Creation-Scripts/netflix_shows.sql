CREATE TABLE public.netflix_shows (
    show_id text NOT NULL,
    type text,
    title text,
    director text,
    cast_members text,
    country text,
    date_added date,
    release_year integer,
    rating text,
    duration text,
    listed_in text,
    description text
);


ALTER TABLE ONLY public.netflix_shows
    ADD CONSTRAINT netflix_shows_pkey PRIMARY KEY (show_id);