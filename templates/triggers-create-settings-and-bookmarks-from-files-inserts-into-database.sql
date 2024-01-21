DROP TRIGGER IF EXISTS {{ db_name }}.create_placeholder_settings;

CREATE TRIGGER {{ db_name }}.create_placeholder_settings 
AFTER INSERT ON {{ db_name }}.files 
FOR EACH ROW 
INSERT IGNORE INTO {{ db_name }}.settings
(
id_file,
kodi_version,
created_at
)
VALUES 
(
NEW.id_file,
NEW.kodi_version,
CURRENT_TIMESTAMP()
);

DROP TRIGGER IF EXISTS {{ db_name }}.create_placeholder_bookmarks;

CREATE TRIGGER {{ db_name }}.create_placeholder_bookmarks 
AFTER INSERT ON {{ db_name }}.files 
FOR EACH ROW 
INSERT IGNORE INTO {{ db_name }}.bookmark
(
id_file,
type,
kodi_version,
created_at
)
VALUES 
(
NEW.id_file,
1,
NEW.kodi_version,
CURRENT_TIMESTAMP()
);