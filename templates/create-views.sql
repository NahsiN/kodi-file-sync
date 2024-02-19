DROP VIEW IF EXISTS {{ db_sync }}.files_w_path;
CREATE VIEW {{ db_sync }}.files_w_path AS
SELECT 
	f.*,
	CONCAT(p.str_path, f.str_filename) AS full_path
FROM
	{{ db_sync }}.files f
JOIN {{ db_sync }}.path p 
ON
	f.id_path = p.id_path
	AND f.kodi_version = p.kodi_version;


DROP VIEW IF EXISTS {{ db_sync }}.files_to_update;
CREATE VIEW {{ db_sync }}.files_to_update AS 
WITH latest_file AS 
(
SELECT 
*,
MAX(IFNULL(updated_at, last_played)) OVER (PARTITION BY full_path) AS latest_updated_at
FROM
{{ db_sync }}.files_w_path),

latest_attributes AS 
(
SELECT
	DISTINCT -- two kodi databases/rows could've the same values due to IFNULL(updated_at, last_played) above
	full_path, latest_updated_at, 
	play_count AS latest_play_count,
	last_played AS latest_last_played,
	date_added AS latest_date_added
FROM 
	latest_file
WHERE latest_updated_at = IFNULL(updated_at, last_played)),

files_to_update AS 
(
SELECT 
    f.*,
    l.latest_updated_at,
    l.latest_play_count,
    l.latest_last_played,
    l.latest_date_added
FROM 
	{{ db_sync }}.files_w_path f 
INNER JOIN
	latest_attributes l
ON 
	f.full_path = l.full_path
WHERE
	-- CASE 1: file exists in all versions and been updated in all version after inserting 
	-- BUT it has either a) been played in all versions  or b) not being played in all versions
	-- CASE 2: file exists in all versions but has not been updated in some versions after inserting
	(IFNULL(f.updated_at, '1800-01-01 00:00:00') < IFNULL(l.latest_updated_at, '1800-01-01 00:00:00')
	AND
	-- This AND condition is here to avoid infinite update loop. If nothing has changed, nothing should be updated
	(
	    IFNULL(f.play_count, -1)  != IFNULL(l.latest_play_count, -1) 
		OR IFNULL(f.last_played, '1800-01-01 00:00:00') != IFNULL(l.latest_last_played, '1800-01-01 00:00:00') 
		OR IFNULL(f.date_added, '1800-01-01 00:00:00') != IFNULL(l.latest_date_added, '1800-01-01 00:00:00')
		))
)
SELECT * FROM files_to_update;


DROP VIEW IF EXISTS {{ db_sync }}.bookmark_w_path;
CREATE VIEW {{ db_sync }}.bookmark_w_path AS
SELECT
	b.*,
	-- f.str_filename, p.str_path,
	-- CONCAT_WS("/", p.str_path, f.str_filename) AS full_path
	CONCAT(p.str_path, f.str_filename) AS full_path
FROM 
	{{ db_sync }}.bookmark b
JOIN
	{{ db_sync }}.files f 
ON 
	b.id_file = f.id_file
	AND b.kodi_version = f.kodi_version
JOIN 
	{{ db_sync }}.`path` p 
ON 
	f.id_path = p.id_path
	AND f.kodi_version = p.kodi_version
	AND b.type = 1;


DROP VIEW IF EXISTS {{ db_sync }}.bookmark_to_update;
CREATE VIEW {{ db_sync }}.bookmark_to_update AS
WITH
latest_bookmark AS 
(
SELECT 
	*, 
	MAX(updated_at) OVER (PARTITION BY full_path) AS latest_updated_at
FROM
	{{ db_sync }}.bookmark_w_path
),

latest_attributes AS
(
SELECT 
	full_path,
	latest_updated_at, 
	time_in_seconds AS latest_time_in_seconds,
	total_time_in_seconds AS latest_total_time_in_seconds,
	player AS latest_player,
	player_state AS latest_player_state
FROM 
	latest_bookmark
WHERE
	latest_updated_at = updated_at
),

bookmark_to_update AS 
(
SELECT
	b.id_bookmark,
	b.id_file,
	b.kodi_version,
	b.type,
	l.latest_time_in_seconds,
	l.latest_total_time_in_seconds,
	l.latest_player,
	l.latest_player_state,
	l.latest_updated_at
	-- b.* , l.* for debugging 
FROM 
	{{ db_sync }}.bookmark_w_path b
INNER JOIN
	latest_attributes l
ON 
	b.full_path = l.full_path
WHERE
	-- CASE 1: bookmark already exist in all versions
	-- CASE 2: bookmark exists in one version but not another
	(IFNULL(b.updated_at, '1800-01-01 00:00:00') < IFNULL(l.latest_updated_at, '1800-01-01 00:00:00')
		AND (
			IFNULL(b.time_in_seconds, -1) != IFNULL(l.latest_time_in_seconds, -1)
		))
)
SELECT
	*
FROM
	bookmark_to_update;


DROP VIEW IF EXISTS {{ db_sync }}.settings_w_path;
CREATE VIEW {{ db_sync }}.settings_w_path AS
SELECT
	s.*,
	CONCAT(p.str_path, f.str_filename) AS full_path
FROM
	{{ db_sync }}.settings s
JOIN {{ db_sync }}.files f 
ON
	s.id_file = f.id_file
	AND s.kodi_version = f.kodi_version
JOIN 
{{ db_sync }}.`path` p
ON
	f.id_path = p.id_path
	AND f.kodi_version = p.kodi_version;


DROP VIEW IF EXISTS {{ db_sync }}.settings_to_update;
CREATE VIEW {{ db_sync }}.settings_to_update AS

WITH latest_settings AS 
(
SELECT
	*,
	MAX(updated_at) OVER (PARTITION BY full_path) AS latest_updated_at
FROM
	{{ db_sync }}.settings_w_path),

latest_attributes AS 
(
SELECT
	full_path AS latest_full_path,
	latest_updated_at,
	deinterlace AS latest_deinterlace,
	view_mode AS latest_view_mode,
	zoom_amount AS latest_zoom_amount, 
	pixel_ratio AS latest_pixel_ratio, 
	vertical_shift AS latest_vertical_shift, 
	audio_stream AS latest_audio_stream, 
	subtitle_stream AS latest_subtitle_stream,
	subtitle_delay AS latest_subtitle_delay, 
	subtitles_on AS latest_subtitles_on, 
	brightness AS latest_brightness, 
	contrast AS latest_contrast, 
	gamma AS latest_gamma,
	volume_amplification AS latest_volume_amplification, 
	audio_delay AS latest_audio_delay, 
	resume_time AS latest_resume_time,
	sharpness AS latest_sharpness, 
	noise_reduction AS latest_noise_reduction, 
	non_lin_stretch AS latest_non_lin_stretch, 
	post_process AS latest_post_process,
	scaling_method AS latest_scaling_method, 
	deinterlace_mode AS latest_deinterlace_mode, 
	stereo_mode AS latest_stereo_mode, 
	stereo_invert AS latest_stereo_invert, 
	video_stream AS latest_video_stream,
	tonemap_method AS latest_tonemap_method, 
	tonemap_param AS latest_tonemap_param, 
	orientation AS latest_orientation, 
	center_mix_level AS latest_center_mix_level
FROM 
		latest_settings
WHERE
	latest_updated_at = updated_at
),

settings_to_update AS 
(
SELECT
	s.*,
	l.latest_updated_at,
	l.latest_deinterlace,
	l.latest_view_mode,
	l.latest_zoom_amount,
	l.latest_pixel_ratio,
	l.latest_vertical_shift,
	l.latest_audio_stream,
	l.latest_subtitle_stream,
	l.latest_subtitle_delay,
	l.latest_subtitles_on,
	l.latest_brightness,
	l.latest_contrast,
	l.latest_gamma,
	l.latest_volume_amplification,
	l.latest_audio_delay,
	l.latest_resume_time,
	l.latest_sharpness,
	l.latest_noise_reduction,
	l.latest_non_lin_stretch,
	l.latest_post_process,
	l.latest_scaling_method,
	l.latest_deinterlace_mode,
	l.latest_stereo_mode,
	l.latest_stereo_invert,
	l.latest_video_stream,
	l.latest_tonemap_method,
	l.latest_tonemap_param,
	l.latest_orientation,
	l.latest_center_mix_level
FROM 
	{{ db_sync }}.settings_w_path s
INNER JOIN
	latest_attributes l
ON
	s.full_path = l.latest_full_path
WHERE
	-- CASE 1: file exists in all versions and settings have been updated in both versions after instering
	-- BUT it has either a) been played and default settings changed in both versions
	-- CASE 2: file exists in all versions but has not been updated in some versions after inserting
(IFNULL(s.updated_at, '1800-01-01 00:00:00') < IFNULL(l.latest_updated_at, '1800-01-01 00:00:00')
	AND	(
		IFNULL(deinterlace, -9999) != IFNULL(latest_deinterlace, -9999)
		OR IFNULL(view_mode, -9999) != IFNULL(latest_view_mode, -9999)
		OR IFNULL(zoom_amount, -9999) != IFNULL(latest_zoom_amount, -9999)
		OR IFNULL(pixel_ratio, -9999) != IFNULL(latest_pixel_ratio, -9999)
		OR IFNULL(vertical_shift, -9999) != IFNULL(latest_vertical_shift, -9999)
		OR IFNULL(audio_stream, -9999) != IFNULL(latest_audio_stream, -9999)
		OR IFNULL(subtitle_stream, -9999) != IFNULL(latest_subtitle_stream, -9999)
		OR IFNULL(subtitle_delay, -9999) != IFNULL(latest_subtitle_delay, -9999)
		OR IFNULL(subtitles_on, -9999) != IFNULL(latest_subtitles_on, -9999)
		OR IFNULL(brightness, -9999) != IFNULL(latest_brightness, -9999)
		OR IFNULL(contrast, -9999) != IFNULL(latest_contrast, -9999)
		OR IFNULL(gamma, -9999) != IFNULL(latest_gamma, -9999)
		OR IFNULL(volume_amplification, -9999) != IFNULL(latest_volume_amplification, -9999)
		OR IFNULL(audio_delay, -9999) != IFNULL(latest_audio_delay, -9999)
		OR IFNULL(resume_time, -9999) != IFNULL(latest_resume_time, -9999)
		OR IFNULL(sharpness, -9999) != IFNULL(latest_sharpness, -9999)
	 	OR IFNULL(noise_reduction, -9999) != IFNULL(latest_noise_reduction, -9999)
		OR IFNULL(non_lin_stretch, -9999) != IFNULL(latest_non_lin_stretch, -9999)
		OR IFNULL(post_process, -9999) != IFNULL(latest_post_process, -9999)
		OR IFNULL(scaling_method, -9999) != IFNULL(latest_scaling_method, -9999)
		OR IFNULL(deinterlace_mode, -9999) != IFNULL(latest_deinterlace_mode, -9999)
		OR IFNULL(stereo_mode, -9999) != IFNULL(latest_stereo_mode, -9999)
		OR IFNULL(stereo_invert, -9999) != IFNULL(latest_stereo_invert, -9999)
		OR IFNULL(video_stream, -9999) != IFNULL(latest_video_stream, -9999)
		OR IFNULL(tonemap_method, -9999) != IFNULL(latest_tonemap_method, -9999)
		OR IFNULL(tonemap_param, -9999) != IFNULL(latest_tonemap_param, -9999)
		OR IFNULL(orientation, -9999) != IFNULL(latest_orientation, -9999)
		OR IFNULL(center_mix_level, -9999) != IFNULL(latest_center_mix_level, -9999)))
)
SELECT
	*
FROM
	settings_to_update;