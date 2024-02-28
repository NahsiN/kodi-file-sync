DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_path_to_kodi_file_sync //

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
	kodi_version = {{ kodi_version }} AND id_path = NEW.idPath //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_files_to_kodi_file_sync //

CREATE TRIGGER {{ db_kodi }}.push_update_files_to_kodi_file_sync AFTER
UPDATE
	ON
	{{ db_kodi }}.files
FOR EACH ROW
BEGIN 
	-- when a file is initially added to Kodi, it is a two step process
	-- 1. insert into files creating a new idFile
	-- 2. Update row with non-null dateAdded
	IF OLD.dateAdded IS NULL AND NEW.dateAdded IS NOT NULL THEN
		/*
			when kodi adds a new file into its database as a result of library import, its does so in
			3 sequential steps which are:
			1) insert into files (idFile, idPath, strFileName) values(NULL, 1, 'fname.mkv')
			2) UPDATE files SET dateAdded='1800-01-01 00:50:00' WHERE idFile=1
			3) update files set playCount=NULL,lastPlayed=NULL where idFile=1
			we prefer to count these steps as part of "creation" and not "update" to preserve the 
			behaviour on how file updates propagate across versions. Hence we
			prefer these steps update the created_at field instead of the updated_at field
		*/
		UPDATE {{ db_sync }}.files
		SET 
		date_added = NEW.dateAdded,
		created_at = CURRENT_TIMESTAMP()
		WHERE 
		kodi_version = {{ kodi_version }} AND id_file = NEW.idFile;
	
	-- update is triggered by another field other than date_added that has changed
	ELSEIF OLD.dateAdded != NEW.dateAdded
			OR IFNULL(OLD.idPath, '/') != IFNULL(NEW.idPath, '/') 
			OR IFNULL(OLD.strFileName, 'foo.mkv') != IFNULL(NEW.strFileName, 'foo.mkv') 
			OR IFNULL(OLD.playCount, -1) != IFNULL(NEW.playCount, -1) 
			OR IFNULL(OLD.lastPlayed, '1800-01-01 00:00:00') != IFNULL(NEW.lastPlayed, '1800-01-01 00:00:00') THEN
		UPDATE {{ db_sync }}.files
		SET 
			date_added = NEW.dateAdded,
			id_path = NEW.idPath,
			str_filename = NEW.strFilename,
			play_count = NEW.playCount,
			last_played = NEW.lastPlayed,
			-- created_at = IF(TIMESTAMPDIFF(SECOND, created_at, CURRENT_TIMESTAMP()) <= 20, 
			-- 				CURRENT_TIMESTAMP(), created_at),
			-- updated_at = IF(TIMESTAMPDIFF(SECOND, created_at, CURRENT_TIMESTAMP()) <= 20, 
			-- 				updated_at, CURRENT_TIMESTAMP())
			updated_at = CURRENT_TIMESTAMP() 
			WHERE 
			kodi_version = {{ kodi_version }} AND id_file = NEW.idFile;
	END IF;
END //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_bookmark_to_kodi_file_sync //

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
		kodi_version={{ kodi_version }} AND id_bookmark=NEW.idBookmark //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_update_settings_to_kodi_file_sync //

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
	kodi_version = {{ kodi_version }} AND id_file = NEW.idFile //