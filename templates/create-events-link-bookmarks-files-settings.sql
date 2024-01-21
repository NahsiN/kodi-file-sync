DROP EVENT IF EXISTS {{ db_sync }}.e_link_bookmarks //
CREATE EVENT {{ db_sync }}.e_link_bookmarks 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 5 MINUTE 
COMMENT 'Link bookmarks across Kodi versions'
DO
BEGIN 
	
UPDATE
	{{ db_sync }}.bookmark b
INNER JOIN {{ db_sync }}.bookmark_to_update u 
ON
	-- b.id_bookmark = u.id_bookmark AND 
	b.id_file = u.id_file
	AND b.kodi_version = u.kodi_version
	AND b.type = u.type
SET 
	b.time_in_seconds = u.latest_time_in_seconds,
	b.total_time_in_seconds = u.latest_total_time_in_seconds,
	b.player = u.latest_player,
	b.player_state = u.latest_player_state,
	b.updated_at = CURRENT_TIMESTAMP();
END //


DROP EVENT IF EXISTS {{ db_sync }}.e_link_files //
CREATE EVENT {{ db_sync }}.e_link_files 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 5 MINUTE 
COMMENT 'Link files across Kodi versions'
DO
BEGIN

UPDATE
	{{ db_sync }}.files f
INNER JOIN {{ db_sync }}.files_to_update u 
ON 
	f.id_file = u.id_file
	AND f.kodi_version = u.kodi_version
SET 
	f.play_count = u.latest_play_count,
	f.last_played = u.latest_last_played,
	f.date_added = u.latest_date_added,
	f.updated_at = CURRENT_TIMESTAMP();
END //


DROP EVENT IF EXISTS {{ db_sync }}.e_link_settings //
CREATE EVENT {{ db_sync }}.e_link_settings 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 5 MINUTE 
COMMENT 'Link settings across Kodi versions'
DO
BEGIN

UPDATE
	{{ db_sync }}.settings s
INNER JOIN {{ db_sync }}.settings_to_update u 
ON 
	s.id_file = u.id_file
	AND s.kodi_version = u.kodi_version
SET 
	s.deinterlace = u.latest_deinterlace,
	s.view_mode = u.latest_view_mode,
	s.zoom_amount = u.latest_zoom_amount, 
	s.pixel_ratio = u.latest_pixel_ratio, 
	s.vertical_shift = u.latest_vertical_shift, 
	s.audio_stream = u.latest_audio_stream, 
	s.subtitle_stream = u.latest_subtitle_stream,
	s.subtitle_delay = u.latest_subtitle_delay, 
	s.subtitles_on = u.latest_subtitles_on, 
	s.brightness = u.latest_brightness, 
	s.contrast = u.latest_contrast, 
	s.gamma = u.latest_gamma,
	s.volume_amplification = u.latest_volume_amplification, 
	s.audio_delay = u.latest_audio_delay, 
	s.resume_time = u.latest_resume_time,
	s.sharpness = u.latest_sharpness, 
	s.noise_reduction = u.latest_noise_reduction, 
	s.non_lin_stretch = u.latest_non_lin_stretch, 
	s.post_process = u.latest_post_process,
	s.scaling_method = u.latest_scaling_method, 
	s.deinterlace_mode = u.latest_deinterlace_mode, 
	s.stereo_mode = u.latest_stereo_mode, 
	s.stereo_invert = u.latest_stereo_invert, 
	s.video_stream = u.latest_video_stream,
	s.tonemap_method = u.latest_tonemap_method, 
	s.tonemap_param = u.latest_tonemap_param, 
	s.orientation = u.latest_orientation, 
	s.center_mix_level = u.latest_center_mix_level,
	s.updated_at = CURRENT_TIMESTAMP(); 
END //