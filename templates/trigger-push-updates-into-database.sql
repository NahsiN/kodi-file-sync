DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_path_to_kodi_file_sync;
CREATE TRIGGER {{ db_kodi }}.push_update_path_to_kodi_file_sync AFTER
UPDATE
	ON
	{{ db_kodi }}.path
FOR EACH ROW 
UPDATE {{ db_sync }}.path 
SET 
	str_path=NEW.strPath,
	str_content=NEW.strContent,
	str_scraper=NEW.strScraper,
	str_hash=NEW.strHash,
	scan_recursive=NEW.scanRecursive,
	use_folder_names=NEW.useFolderNames,
	str_settings=NEW.strSettings,
	no_update=NEW.noUpdate,
	exclude=NEW.exclude,
	{%if kodi_version >= 19 %}
	all_audio=NEW.allAudio,
	{% endif %}
	date_added=NEW.dateAdded,
	id_parent_path=NEW.idParentPath,
	updated_at=CURRENT_TIMESTAMP()
	WHERE
	kodi_version = {{ kodi_version }} AND id_path = NEW.idPath;


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_files_to_kodi_file_sync;
CREATE TRIGGER {{ db_kodi }}.push_update_files_to_kodi_file_sync AFTER
UPDATE
	ON
	{{ db_kodi }}.files
FOR EACH ROW 
UPDATE {{ db_sync }}.files
SET 
	id_path=NEW.idPath,
	str_filename=NEW.strFilename,
	play_count=NEW.playCount,
	last_played=NEW.lastPlayed,
	date_added=NEW.dateAdded,
	updated_at=CURRENT_TIMESTAMP() 
	WHERE 
	kodi_version = {{ kodi_version }} AND id_file = NEW.idFile;


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_bookmark_to_kodi_file_sync;
CREATE TRIGGER {{ db_kodi }}.push_update_bookmark_to_kodi_file_sync AFTER
UPDATE
	ON
	{{ db_kodi }}.bookmark 
FOR EACH ROW 
UPDATE	
	{{ db_sync }}.bookmark
SET
	id_bookmark=NEW.idBookmark,
	id_file=NEW.idFile,
	time_in_seconds=NEW.timeInSeconds,
	total_time_in_seconds=NEW.totalTimeInSeconds,
	thumbnail_image=NEW.thumbNailImage,
	player=NEW.player,
	player_state=NEW.playerState,
	type=NEW.type,
	updated_at=CURRENT_TIMESTAMP() 
	WHERE 
		kodi_version={{ kodi_version }} AND id_bookmark=NEW.idBookmark;


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_settings_to_kodi_file_sync;
CREATE TRIGGER {{ db_kodi }}.push_update_settings_to_kodi_file_sync AFTER UPDATE 
ON {{ db_kodi }}.settings 
FOR EACH ROW
UPDATE {{ db_sync }}.settings SET
	deinterlace = NEW.Deinterlace,
	view_mode = NEW.ViewMode,
	zoom_amount = NEW.ZoomAmount, 
	pixel_ratio = NEW.PixelRatio, 
	vertical_shift = NEW.VerticalShift, 
	audio_stream = NEW.AudioStream, 
	subtitle_stream = NEW.SubtitleStream,
	subtitle_delay = NEW.SubtitleDelay, 
	subtitles_on = NEW.SubtitlesOn, 
	brightness = NEW.Brightness, 
	contrast = NEW.Contrast, 
	gamma = NEW.Gamma,
	volume_amplification = NEW.VolumeAmplification, 
	audio_delay = NEW.AudioDelay, 
	resume_time = NEW.ResumeTime,
	sharpness = NEW.Sharpness, 
	noise_reduction = NEW.NoiseReduction, 
	non_lin_stretch = NEW.NonLinStretch, 
	post_process = NEW.PostProcess,
	scaling_method = NEW.ScalingMethod, 
	deinterlace_mode = NEW.DeinterlaceMode, 
	stereo_mode = NEW.StereoMode, 
	stereo_invert = NEW.StereoInvert, 
	video_stream = NEW.VideoStream,
	tonemap_method = NEW.TonemapMethod, 
	tonemap_param = NEW.TonemapParam, 
	orientation = NEW.Orientation, 
	center_mix_level = NEW.CenterMixLevel,
	updated_at = CURRENT_TIMESTAMP()
WHERE
	kodi_version = {{ kodi_version }} AND id_file = NEW.idFile;