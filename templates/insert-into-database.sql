-- **************path insert*************************
INSERT
	INTO
	{{ db_sync }}.path
SELECT
	p.idPath AS id_path,
	p.strPath AS str_path,
	p.strContent AS str_content,
	p.strScraper AS str_scraper,
	p.strHash AS str_hash,
	p.scanRecursive AS scan_recursive,
	p.useFolderNames AS use_folder_names,
	p.strSettings AS str_settings,
	p.noUpdate AS no_update,
	p.exclude AS exclude,
	{% if kodi_version >= 19 %}
	p.allAudio AS all_audio,
	{% elif kodi_version < 19 %}
	NULL AS all_audio,
	{% endif %}
	p.dateAdded AS date_added,
	p.idParentPath AS id_parent_path,
	{{ kodi_version }} AS kodi_version,
	CURRENT_TIMESTAMP() AS created_at,
	NULL AS updated_at
FROM
	{{ db_kodi }}.path p;


-- *******************files insert***********************
INSERT
	INTO
	{{ db_sync }}.files 
SELECT
	f.idFile AS id_file,
	f.idPath AS id_path,
	f.strFilename AS str_filename,
	f.playCount AS play_count,
	f.lastPlayed AS last_played,
	f.dateAdded AS date_added,
	{{ kodi_version }} AS kodi_version,
	CURRENT_TIMESTAMP() AS created_at,
	CURRENT_TIMESTAMP() AS updated_at -- to sync files across versions after initial setup
FROM
	{{ db_kodi }}.files f;

-- *******************bookmarks insert*********************
-- insert non-resume type bookmarks
INSERT
	INTO
	{{ db_sync }}.bookmark 
SELECT
	b.idBookmark AS id_bookmark,
	b.idFile AS id_file,
	b.timeInSeconds AS time_in_seconds,
	b.totalTimeInSeconds AS total_time_in_seconds,
	b.thumbNailImage AS thumbnail_image,
	b.player AS player,
	b.playerState AS player_state,
	b.type AS type,
	{{ kodi_version }} AS kodi_version,
	CURRENT_TIMESTAMP() AS created_at,
	NULL AS updated_at
FROM
	{{ db_kodi }}.bookmark b
WHERE	
	b.type != 1;

-- update resume type bookmarks because placeholder values were created when inserting into files
UPDATE {{ db_sync }}.bookmark bf INNER JOIN {{ db_kodi }}.bookmark bv
ON bf.id_file = bv.idFile AND bf.type = bv.type
SET 
	bf.id_bookmark = bv.idBookmark,
	bf.time_in_seconds = bv.timeInSeconds,
	bf.total_time_in_seconds = bv.totalTimeInSeconds,
	bf.thumbnail_image = bv.thumbNailImage,
	bf.player = bv.player,
	bf.player_state = bv.playerState,
	bf.updated_at = CURRENT_TIMESTAMP() 
WHERE 	
	bf.kodi_version = {{ kodi_version }} AND bf.type = 1;


-- ***************settings insert**********************
UPDATE {{ db_sync }}.settings sf INNER JOIN {{ db_kodi }}.settings sv 
ON sf.id_file = sv.idFile 
SET 
	sf.deinterlace = sv.Deinterlace,
	sf.view_mode = sv.ViewMode,
	sf.zoom_amount = sv.ZoomAmount, 
	sf.pixel_ratio = sv.PixelRatio, 
	sf.vertical_shift = sv.VerticalShift, 
	sf.audio_stream = sv.AudioStream, 
	sf.subtitle_stream = sv.SubtitleStream,
	sf.subtitle_delay = sv.SubtitleDelay, 
	sf.subtitles_on = sv.SubtitlesOn, 
	sf.brightness = sv.Brightness, 
	sf.contrast = sv.Contrast, 
	sf.gamma = sv.Gamma,
	sf.volume_amplification = sv.VolumeAmplification, 
	sf.audio_delay = sv.AudioDelay, 
	sf.resume_time = sv.ResumeTime,
	sf.sharpness = sv.Sharpness, 
	sf.noise_reduction = sv.NoiseReduction, 
	sf.non_lin_stretch = sv.NonLinStretch, 
	sf.post_process = sv.PostProcess,
	sf.scaling_method = sv.ScalingMethod, 
	sf.deinterlace_mode = sv.DeinterlaceMode, 
	sf.stereo_mode = sv.StereoMode, 
	sf.stereo_invert = sv.StereoInvert, 
	sf.video_stream = sv.VideoStream,
	sf.tonemap_method = sv.TonemapMethod, 
	sf.tonemap_param = sv.TonemapParam, 
	sf.orientation = sv.Orientation, 
	sf.center_mix_level = sv.CenterMixLevel,
	sf.updated_at = CURRENT_TIMESTAMP()
WHERE
	sf.kodi_version = {{ kodi_version }};