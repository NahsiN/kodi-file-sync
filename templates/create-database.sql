DROP DATABASE IF EXISTS {{ db_name }};
CREATE DATABASE {{ db_name }};

CREATE TABLE {{ db_name }}.path ( 
	id_path integer, 
	str_path text, 
	str_content text, 
	str_scraper text, 
	str_hash text, 
	scan_recursive integer, 
	use_folder_names bool, 
	str_settings text, 
	no_update bool, 
	exclude bool, 
	all_audio bool, 
	date_added text, 
	id_parent_path integer,
	kodi_version integer,
	created_at timestamp,
	updated_at timestamp,
	PRIMARY KEY (kodi_version, id_path)
);

CREATE INDEX ix_path_1 ON {{ db_name }}.path
	(kodi_version, str_path(255));

CREATE INDEX ix_path_2 ON {{ db_name }}.path 
	(kodi_version, id_parent_path);

CREATE INDEX ix_path_3 ON {{ db_name }}.path
	(kodi_version, id_path);

CREATE INDEX ix_path_t1 ON {{ db_name }}.path
	(created_at);

CREATE INDEX ix_path_t2 ON {{ db_name }}.path
	(updated_at);

DROP TABLE IF EXISTS {{ db_name }}.files;

CREATE TABLE {{ db_name }}.files (
	id_file int, 
	id_path int, 
	str_filename text, 
	play_count int, 
	last_played text, 
	date_added text,
	kodi_version integer,
	created_at timestamp,
	updated_at timestamp,
	PRIMARY key (kodi_version, id_file),
	
	FOREIGN KEY (kodi_version, id_path) REFERENCES 
		{{ db_name }}.path (kodi_version, id_path) 
		ON DELETE CASCADE ON UPDATE CASCADE 
);

CREATE INDEX ix_files_1 ON {{ db_name }}.files
(kodi_version, id_path, str_filename(255));

CREATE INDEX ix_files_t1 ON {{ db_name }}.files
	(created_at);

CREATE INDEX ix_files_t2 ON {{ db_name }}.files
	(updated_at);



DROP TABLE IF EXISTS {{ db_name }}.bookmark;

CREATE TABLE {{ db_name }}.bookmark (
	id_bookmark int,
	id_file int, 
	time_in_seconds double, 
	total_time_in_seconds double, 
	thumbnail_image text, 
	player text, 
	player_state text, 
	type integer,
	kodi_version int,
	created_at timestamp,
	updated_at timestamp,
-- 	PRIMARY KEY (kodi_version, id_bookmark),
	
	-- add foreign key references files table
	FOREIGN KEY (kodi_version, id_file) REFERENCES
	{{ db_name }}.files (kodi_version, id_file)
	ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX ix_bookmark_1 ON {{ db_name }}.bookmark (kodi_version, id_bookmark);

CREATE INDEX ix_bookmark_2 ON
{{ db_name }}.bookmark (kodi_version, id_file);

CREATE INDEX ix_bookmark_t1 ON {{ db_name }}.bookmark
	(created_at);

CREATE INDEX ix_bookmark_t2 ON {{ db_name }}.bookmark
	(updated_at);




DROP TABLE IF EXISTS {{ db_name }}.settings;

CREATE TABLE {{ db_name }}.settings ( 
	id_file integer, 
	deinterlace bool,
	view_mode integer,
	zoom_amount float, 
	pixel_ratio float, 
	vertical_shift float, 
	audio_stream integer, 
	subtitle_stream integer,
	subtitle_delay float, 
	subtitles_on bool, 
	brightness float, 
	contrast float, 
	gamma float,
	volume_amplification float, 
	audio_delay float, 
	resume_time integer,
	sharpness float, 
	noise_reduction float, 
	non_lin_stretch bool, 
	post_process bool,
	scaling_method integer, 
	deinterlace_mode integer, 
	stereo_mode integer, 
	stereo_invert bool, 
	video_stream integer,
	tonemap_method integer, 
	tonemap_param float, 
	orientation integer, 
	center_mix_level integer,
	kodi_version integer,
	created_at timestamp,
	updated_at timestamp,	
	
	PRIMARY KEY (kodi_version, id_file),
	
	FOREIGN KEY (kodi_version, id_file) REFERENCES
	{{ db_name }}.files (kodi_version, id_file) 
	ON DELETE CASCADE ON UPDATE CASCADE
	);

CREATE INDEX ix_settings ON {{ db_name }}.settings ( kodi_version, id_file );

CREATE INDEX ix_settings_t1 ON {{ db_name }}.settings
	(created_at);

CREATE INDEX ix_settings_t2 ON {{ db_name }}.settings
	(updated_at);
