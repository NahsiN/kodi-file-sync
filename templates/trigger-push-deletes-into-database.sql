DROP TRIGGER IF EXISTS {{ db_kodi }}.push_path_delete_to_kodi_file_sync //
CREATE TRIGGER {{ db_kodi }}.push_path_delete_to_kodi_file_sync AFTER DELETE 
ON {{ db_kodi }}.path 
FOR EACH ROW 
	DELETE FROM {{ db_sync }}.path WHERE kodi_version = {{ kodi_version }} AND id_path = OLD.idPath //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_files_delete_to_kodi_file_sync //
CREATE TRIGGER {{ db_kodi }}.push_files_delete_to_kodi_file_sync AFTER DELETE 
ON {{ db_kodi }}.files 
FOR EACH ROW 
	DELETE FROM {{ db_sync }}.files WHERE kodi_version = {{ kodi_version }} AND id_file = OLD.idFile //


DROP TRIGGER IF EXISTS {{ db_kodi }}.push_bookmark_delete_to_kodi_file_sync //
CREATE TRIGGER {{ db_kodi }}.push_bookmark_delete_to_kodi_file_sync AFTER DELETE
ON {{ db_kodi }}.bookmark 
FOR EACH ROW
	BEGIN
		IF OLD.type != 1 THEN 
			DELETE FROM {{ db_sync }}.bookmark 
            WHERE kodi_version = {{ kodi_version }} AND id_file = OLD.idFile AND type != 1;
		ELSEIF OLD.type = 1 THEN
			UPDATE {{ db_sync }}.bookmark 
			SET
		 		id_bookmark = NULL,
		 		time_in_seconds = NULL,
		 		total_time_in_seconds = NULL,
		 		thumbnail_image = NULL,
		 		player = NULL,
		 		player_state = NULL,
		 		updated_at = CURRENT_TIMESTAMP()
		 		WHERE
		 			kodi_version = {{ kodi_version }} AND id_file = OLD.idFile AND type = 1;
		END IF;	
	END //