DROP EVENT IF EXISTS {{ db_sync }}.e_sync_bookmark_{{ kodi_version }} //
CREATE EVENT {{ db_sync }}.e_sync_bookmark_{{ kodi_version }} 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 8 MINUTE 
COMMENT 'Sync bookmarks to kodi {{ kodi_version }}'
DO
BEGIN

CREATE TEMPORARY TABLE {{ db_sync }}.temp_bookmark_update_{{ kodi_version }}
WITH 
bookmark_file_sync AS 
(SELECT * FROM {{ db_sync }}.bookmark b 
WHERE
	kodi_version = {{ kodi_version }}
	-- CASE 1: new bookmark needs to be created time_in_seconds IS NOT NULL
	-- CASE 2: existing bookmark needs to updated time_in_seconds IS NOT NULL
	-- CASE 3: existing bookmark needs to be deleted from Kodi Database: time_in_seconds IS NULL but id_bookmark IS NOT NULL 
	AND (time_in_seconds IS NOT NULL OR id_bookmark IS NOT NULL) 
	AND b.type = 1
),

bookmark_version AS 
(
SELECT * FROM {{ db_kodi }}.bookmark WHERE type = 1 
),

bookmarks_to_update AS 
(
SELECT 
	bf.id_bookmark AS new_idBookmark,
	bf.id_file AS new_idFile,
	bf.time_in_seconds AS new_timeInSeconds,
	bf.total_time_in_seconds AS new_totalTimeInSeconds,
	bf.player AS new_player,
	bf.player_state AS new_playerState,
	bf.type AS new_type
-- 	bf.*
	-- , bv.* 
FROM bookmark_file_sync bf 
LEFT JOIN bookmark_version bv 
ON bf.id_file = bv.idFile
WHERE 
	-- CASE 1 existing bookmark
	-- CASE 2 non existing bookmark
	IFNULL(bf.time_in_seconds, -1) != IFNULL(bv.timeInSeconds, -1)
)

SELECT * FROM bookmarks_to_update;

INSERT INTO {{ db_kodi }}.bookmark 
(idBookmark, idFile, timeInSeconds, 
totalTimeInSeconds, player, playerState, type)
SELECT
	new_idBookmark,
	new_idFile,
	new_timeInSeconds,
	new_totalTimeInSeconds,
	new_player,
	new_playerState,
	new_type 
FROM 
	{{ db_sync }}.temp_bookmark_update_{{ kodi_version }} u
WHERE 
	new_timeInSeconds IS NOT NULL
ON DUPLICATE KEY UPDATE
	idFile = u.new_idFile,
	timeInSeconds = u.new_timeInSeconds,
	totalTimeInSeconds = u.new_totalTimeInSeconds,
	player = u.new_player,
	playerState = u.new_playerState,
	type = u.new_type;

DELETE FROM MyVideos119.bookmark WHERE idBookmark IN 
(SELECT new_idBookmark FROM {{ db_sync }}.temp_bookmark_update_{{ kodi_version }} u 
WHERE new_timeInSeconds IS NULL);

DROP TEMPORARY TABLE {{ db_sync }}.temp_bookmark_update_{{ kodi_version }};
END //


DROP EVENT IF EXISTS {{ db_sync }}.e_sync_files_{{ kodi_version }} //
CREATE EVENT {{ db_sync }}.e_sync_files_{{ kodi_version }} 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 8 MINUTE 
COMMENT 'Sync files to kodi {{ kodi_version }}'
DO
BEGIN

CREATE TEMPORARY TABLE {{ db_sync }}.temp_files_update_{{ kodi_version }}

WITH files_file_sync AS (
SELECT * FROM {{ db_sync }}.files f 
WHERE f.kodi_version = {{ kodi_version }} AND f.last_played IS NOT NULL
),

files_version AS 
(SELECT * FROM {{ db_kodi }}.files),

files_to_update AS 
(
SELECT 
	f.id_file,
	f.str_filename,
	f.play_count AS new_playCount,
	f.last_played AS new_lastPlayed,
	f.date_added AS new_dateAdded,
	v.playCount AS old_playCount,
	v.lastPlayed AS old_lastPlayed,
	v.dateAdded AS old_dateAdded
FROM files_file_sync f 
INNER JOIN 
files_version v 
ON f.id_file = v.idFile
WHERE
	IFNULL(f.play_count, -1) != IFNULL(v.playCount, -1)
	OR IFNULL(f.last_played, '1800-01-01 00:00:00') != IFNULL(v.lastPlayed, '1800-01-01 00:00:00')
	OR IFNULL(f.date_added, '1800-01-01 00:00:00') != IFNULL(v.dateAdded, '1800-01-01 00:00:00')
)

SELECT * FROM files_to_update;

UPDATE {{ db_kodi }}.files f 
INNER JOIN {{ db_sync }}.temp_files_update_{{ kodi_version }} u 
ON f.idFile = u.id_file
SET 
	f.playCount = u.new_playCount,
	f.lastPlayed = u.new_lastPlayed,
	f.dateAdded = u.new_dateAdded;

DROP TEMPORARY TABLE {{ db_sync }}.temp_files_update_{{ kodi_version }};

END //


DROP EVENT IF EXISTS {{ db_sync }}.e_sync_settings_{{ kodi_version }} //
CREATE EVENT {{ db_sync }}.e_sync_settings_{{ kodi_version }} 
ON
SCHEDULE EVERY 5 MINUTE STARTS "2023-12-23 22:00" + INTERVAL 8 MINUTE 
COMMENT 'Sync settings to kodi {{ kodi_version }}'
DO
BEGIN

CREATE TEMPORARY TABLE {{ db_sync }}.temp_settings_update_{{ kodi_version }}

WITH 
settings_file_sync AS 
(SELECT * FROM {{ db_sync }}.settings s  
WHERE 
	s.kodi_version = {{ kodi_version }} 
	AND video_stream IS NOT NULL AND audio_stream IS NOT NULL 
),

settings_version AS 
(SELECT * FROM {{ db_kodi }}.settings s),

settings_to_update AS 
(
SELECT 
	sf.id_file AS new_id_file,
	sf.deinterlace AS new_deinterlace,
	sf.view_mode AS new_view_mode,
	sf.zoom_amount AS new_zoom_amount, 
	sf.pixel_ratio AS new_pixel_ratio, 
	sf.vertical_shift AS new_vertical_shift, 
	sf.audio_stream AS new_audio_stream, 
	sf.subtitle_stream AS new_subtitle_stream,
	sf.subtitle_delay AS new_subtitle_delay, 
	sf.subtitles_on AS new_subtitles_on, 
	sf.brightness AS new_brightness, 
	sf.contrast AS new_contrast, 
	sf.gamma AS new_gamma,
	sf.volume_amplification AS new_volume_amplification, 
	sf.audio_delay AS new_audio_delay, 
	sf.resume_time AS new_resume_time,
	sf.sharpness AS new_sharpness, 
	sf.noise_reduction AS new_noise_reduction, 
	sf.non_lin_stretch AS new_non_lin_stretch, 
	sf.post_process AS new_post_process,
	sf.scaling_method AS new_scaling_method, 
	sf.deinterlace_mode AS new_deinterlace_mode, 
	sf.stereo_mode AS new_stereo_mode, 
	sf.stereo_invert AS new_stereo_invert, 
	sf.video_stream AS new_video_stream,
	sf.tonemap_method AS new_tonemap_method, 
	sf.tonemap_param AS new_tonemap_param, 
	sf.orientation AS new_orientation, 
	sf.center_mix_level AS new_center_mix_level
FROM settings_file_sync sf 
LEFT JOIN settings_version sv 
ON sf.id_file = sv.idFile
WHERE 
-- CASE 1 existing settings
-- CASE 2 non existing settings
-- bf.time_in_seconds != bv.timeInSeconds 
	IFNULL(sf.deinterlace, -9999) != IFNULL(sv.Deinterlace, -9999)
	OR IFNULL(sf.view_mode, -9999) != IFNULL(sv.ViewMode, -9999)
	OR IFNULL(sf.zoom_amount, -9999) != IFNULL(sv.ZoomAmount, -9999)
	OR IFNULL(sf.pixel_ratio, -9999) != IFNULL(sv.PixelRatio, -9999)
	OR IFNULL(sf.vertical_shift, -9999) != IFNULL(sv.VerticalShift, -9999)
	OR IFNULL(sf.audio_stream, -9999) != IFNULL(sv.AudioStream, -9999)
	OR IFNULL(sf.subtitle_stream, -9999) != IFNULL(sv.SubtitleStream, -9999)
	OR IFNULL(sf.subtitle_delay, -9999) != IFNULL(sv.SubtitleDelay, -9999)
	OR IFNULL(sf.subtitles_on, -9999) != IFNULL(sv.SubtitlesOn, -9999)
	OR IFNULL(sf.brightness, -9999) != IFNULL(sv.Brightness, -9999)
	OR IFNULL(sf.contrast, -9999) != IFNULL(sv.Contrast, -9999)
	OR IFNULL(sf.gamma, -9999) != IFNULL(sv.Gamma, -9999)
	OR IFNULL(sf.volume_amplification, -9999) != IFNULL(sv.VolumeAmplification, -9999)
	OR IFNULL(sf.audio_delay, -9999) != IFNULL(sv.AudioDelay, -9999)
	OR IFNULL(sf.resume_time, -9999) != IFNULL(sv.ResumeTime, -9999)
	OR IFNULL(sf.sharpness, -9999) != IFNULL(sv.Sharpness, -9999)
 	OR IFNULL(sf.noise_reduction, -9999) != IFNULL(sv.NoiseReduction, -9999)
	OR IFNULL(sf.non_lin_stretch, -9999) != IFNULL(sv.NonLinStretch, -9999)
	OR IFNULL(sf.post_process, -9999) != IFNULL(sv.PostProcess, -9999)
	OR IFNULL(sf.scaling_method, -9999) != IFNULL(sv.ScalingMethod, -9999)
	OR IFNULL(sf.deinterlace_mode, -9999) != IFNULL(sv.DeinterlaceMode, -9999)
	OR IFNULL(sf.stereo_mode, -9999) != IFNULL(sv.StereoMode, -9999)
	OR IFNULL(sf.stereo_invert, -9999) != IFNULL(sv.StereoInvert, -9999)
	OR IFNULL(sf.video_stream, -9999) != IFNULL(sv.VideoStream, -9999)
	OR IFNULL(sf.tonemap_method, -9999) != IFNULL(sv.TonemapMethod, -9999)
	OR IFNULL(sf.tonemap_param, -9999) != IFNULL(sv.TonemapParam, -9999)
	OR IFNULL(sf.orientation, -9999) != IFNULL(sv.Orientation, -9999)
	OR IFNULL(sf.center_mix_level, -9999) != IFNULL(sv.CenterMixLevel, -9999)
)

-- insert into temp table
SELECT * FROM settings_to_update;

INSERT INTO {{ db_kodi }}.settings 
(idFile, Deinterlace, ViewMode,
ZoomAmount, PixelRatio, VerticalShift,
AudioStream, SubtitleStream, SubtitleDelay,
SubtitlesOn, Brightness, Contrast,
Gamma, VolumeAmplification, AudioDelay,
ResumeTime, Sharpness, NoiseReduction,
NonLinStretch, PostProcess, ScalingMethod,
DeinterlaceMode, StereoMode, StereoInvert,
VideoStream, TonemapMethod, TonemapParam,
Orientation, CenterMixLevel)
SELECT	
	new_id_file AS idFile,
	new_deinterlace AS Deinterlace,
	new_view_mode AS ViewMode,
	new_zoom_amount AS ZoomAmount, 
	new_pixel_ratio AS PixelRatio,
	new_vertical_shift AS VerticalShift,
	new_audio_stream AS AudioStream,
	new_subtitle_stream AS SubtitleStream,
	new_subtitle_delay AS SubtitleDelay, 
	new_subtitles_on AS SubtitlesOn,
	new_brightness AS Brightness, 
	new_contrast AS Contrast,
	new_gamma AS Gamma,
	new_volume_amplification AS VolumeAmplification, 
	new_audio_delay AS AudioDelay, 
	new_resume_time AS ResumeTime,
	new_sharpness AS Sharpness,
	new_noise_reduction AS NoiseReduction, 
	new_non_lin_stretch AS NonLinStretch, 
	new_post_process AS PostProcess,
	new_scaling_method AS ScalingMethod,
	new_deinterlace_mode AS DeinterlaceMode, 
	new_stereo_mode AS StereoMode,
	new_stereo_invert AS StereoInvert,
	new_video_stream AS VideoStream,
	new_tonemap_method AS TonemapMethod, 
	new_tonemap_param AS TonemapParam,
	new_orientation AS Orientation,
	new_center_mix_level AS CenterMixLevel
FROM 
	{{ db_sync }}.temp_settings_update_{{ kodi_version }} u
ON DUPLICATE KEY UPDATE
	idFile = u.new_id_file,
	Deinterlace = u.new_deinterlace,
	ViewMode = u.new_view_mode,
	ZoomAmount = new_zoom_amount, 
	PixelRatio = new_pixel_ratio,
	VerticalShift = new_vertical_shift,
	AudioStream = new_audio_stream,
	SubtitleStream = new_subtitle_stream,
	SubtitleDelay = new_subtitle_delay, 
	SubtitlesOn = new_subtitles_on,
	Brightness = new_brightness, 
	Contrast = new_contrast,
	Gamma = new_gamma,
	VolumeAmplification = new_volume_amplification, 
	AudioDelay = new_audio_delay, 
	ResumeTime = new_resume_time,
	Sharpness = new_sharpness,
	NoiseReduction = new_noise_reduction, 
	NonLinStretch = new_non_lin_stretch, 
	PostProcess = new_post_process,
	ScalingMethod = new_scaling_method,
	DeinterlaceMode = new_deinterlace_mode, 
	StereoMode = new_stereo_mode,
	StereoInvert = new_stereo_invert,
	VideoStream = new_video_stream,
	TonemapMethod = new_tonemap_method, 
	TonemapParam = new_tonemap_param,
	Orientation = new_orientation,
	CenterMixLevel = new_center_mix_level;

DROP TEMPORARY TABLE {{ db_sync }}.temp_settings_update_{{ kodi_version }};

END //