DROP TRIGGER IF EXISTS {{ db_kodi }}.push_insert_path_to_kodi_file_sync //

CREATE TRIGGER {{ db_kodi }}.push_insert_path_to_kodi_file_sync AFTER
INSERT
	ON
	{{ db_kodi }}.path
FOR EACH ROW 
INSERT
	IGNORE
INTO
	{{ db_sync }}.path 
(
	id_path,
	str_path,
	str_content,
	str_scraper,
	str_hash,
	scan_recursive,
	use_folder_names,
	str_settings,
	no_update,
	exclude,
	all_audio,
	date_added,
	id_parent_path,
	kodi_version,
	created_at
)
VALUES
( NEW.idPath,
	NEW.strPath ,
	NEW.strContent,
	NEW.strScraper,
	NEW.strHash,
	NEW.scanRecursive,
	NEW.useFolderNames,
	NEW.strSettings,
	NEW.noUpdate,
	NEW.exclude,
	NEW.allAudio,
	NEW.dateAdded,
	NEW.idParentPath,
	{{ kodi_version }},
	CURRENT_TIMESTAMP()
	) //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_insert_files_to_kodi_file_sync //

CREATE TRIGGER {{ db_kodi }}.push_insert_files_to_kodi_file_sync AFTER
INSERT
	ON
	{{ db_kodi }}.files
FOR EACH ROW 
INSERT
	IGNORE
INTO
	{{ db_sync }}.files 
(
	id_file,
	id_path,
	str_filename,
	play_count,
	last_played,
	date_added,
	kodi_version,
	created_at
)
VALUES
( NEW.idFile,
	NEW.idPath,
	NEW.strFilename,
	NEW.playCount,
	NEW.lastPlayed,
	NEW.dateAdded,
	{{ kodi_version }},
	CURRENT_TIMESTAMP()
	) //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_insert_bookmark_to_kodi_file_sync //

CREATE TRIGGER {{ db_kodi }}.push_insert_bookmark_to_kodi_file_sync AFTER
INSERT
	ON
	{{ db_kodi }}.bookmark 
FOR EACH ROW 
BEGIN
	IF NEW.type != 1 THEN
		INSERT IGNORE INTO {{ db_sync }}.bookmark
		(id_bookmark,
		id_file,
		time_in_seconds,
		total_time_in_seconds,
		thumbnail_image,
		player,
		player_state,
		type,
		kodi_version,
		created_at)
		VALUES
		(NEW.idBookmark,
		NEW.idFile,
		NEW.timeInSeconds,
		NEW.totalTimeInSeconds,
		NEW.thumbNailImage,
		NEW.player,
		NEW.playerState,
		NEW.type,
		{{ kodi_version }},
		CURRENT_TIMESTAMP());
 	
 	ELSEIF NEW.type = 1 THEN
 		UPDATE {{ db_sync }}.bookmark
 		SET
 		id_bookmark = NEW.idBookmark,
 		time_in_seconds = NEW.timeInSeconds,
 		total_time_in_seconds = NEW.totalTimeInSeconds,
 		thumbnail_image = NEW.thumbNailImage,
 		player = NEW.player,
 		player_state = NEW.playerState,
 		updated_at = CURRENT_TIMESTAMP()
 		WHERE
 			id_file = NEW.idFile AND kodi_version = {{ kodi_version }} AND type = 1;
	END IF;
END //

DROP TRIGGER IF EXISTS {{ db_kodi }}.push_insert_settings_to_kodi_file_sync //

CREATE TRIGGER {{ db_kodi }}.push_insert_settings_to_kodi_file_sync AFTER INSERT 
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