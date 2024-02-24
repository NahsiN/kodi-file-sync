# KodiFileSync 🔄
If using a central database server to manage your Kodi library, e.g. [MySQL](https://kodi.wiki/view/MySQL), 
this project aims to _sync certain video file metadata across Kodi versions_. The metadata includes 
resume type bookmarks, settings such as audio or subtitle track, play counts, last played etc.
The metadata _excludes_ metadata such as movie/tv show names, ratings, actors, genres etc. 


# Installation
1. Clone this repo onto your machine and use it as your working directory for everything below.
2. Create a `.env` file using `touch .env`. Populate it with your MySQL server credentials. For e.g.
```
MYSQL_HOST = "000.000.0.000"
MYSQL_USER = "0000"
MYSQL_PASSWORD = "0000"
MYSQL_PORT = 0000
```
3. Set up a Python virtual environment using a virtual env tool of your choice (venv, virtualenv, conda, poetry,pipenv, pyflow). See [comparison](https://dev.to/bowmanjd/python-tools-for-managing-virtual-environments-3bko) 
I will be using venv. 
    - Create a virtual enviroment called kfs in your working directory `python -m venv kfs`
    - Activate the virtual environment using `source kfs/bin/activate` or if on Windows `source kfs/Scripts/activate`
    - Install `pip-tools` in the virutal environment by `pip install pip-tools`
4. Install dependencies
    - Identitfy the `requirements/[env]-requirements.txt` file where `[env]` denotes the appropriate python environment you're in, namely your OS and python version. I'll use `requirements/linux-py3.8-requirements.txt` from now on.
        - If a `requirements/[env]-requirements.txt` file does not exist for your python environment, then create one by running `pip-compile  --output-file requirements/{os}-{python-version}-requirements.txt`
    - Install the requriements in the virtual env by running `pip-sync requirements/linux-py3.8-requirements.txt`
        
5. Modify the `config.yaml`
    - Enter the kodi version and associated databases you'd like to keep in sync. Refer to the [wiki](https://kodi.wiki/view/Databases) to find out the default database names for different Kodi versions. NOTE: One line per Kodi version. Syncing multiple databases per Kodi version to another Kodi version is not yet supported.
6. Run Script `python sync.py` This will create the database, triggers, inserts, events necessary for file syncing
7. Deactivate the environment using `deactivate`. Test it out


# Syncing Behaviour 
In an ideal world, the ask is that the most _appropriate_ state of the bookmarks, settings or files tables be synced across Kodi versions. Often 
most appropriate means the same thing as recent most recent but not in all cases. Below I describe how this project aims to resolve 
the conflicts that arise when these 3 tables become out of sync different Kodi versions.

- During the initial setup, the order of the list specified in `kodi_dbs` in `config.yaml` determines which database's contents are synced with the rest. For e.g. if 
```
kodi_dbs:
  - !!python/tuple [18, "MyVideos116"]
  - !!python/tuple [19, "MyVideos119"]
  - !!python/tuple [20, "MyVideos121"]
```
then the contents of the tables `files, bookmarks, settings` in database `MyVideos121` will be synced with the others. Not necessarily true, e.g. with files or bookmarks.


During the initial sync, the order of syncing is defined for the different tables as:
- bookmarks
    - if only one bookmark exists across versions for a given file, then that bookmark is synced across versions
    - else if multiple bookmarks exist across versions for a given file, then the order of the list specified in `kodi_dbs` in `config.yaml` determines which bookmark is synced across versions
- settings
    - if only one play setting exists across versions for a given file, then that setting is synced across versions
    - else if multiple play settings exist across versions for a given file, then the order of the list specified in `kodi_dbs` in `config.yaml` determines which setting is synced across versions 
- files
    - the most recent `last_played` field value resolves the conflict across Kodi versions for the same file 

Post initial sync and during normal operation, the syncing is defined by
- bookmarks
    - the most recent bookmark update is synced across versions
    - deleting a bookmark (by either resetting resume position or finish watching the file) is synced across versions
- settings
    - the most recent settings update is synced across versions
- files
    - if the same file already exists in multiple versions, then the most recent updates to the file is synced across versions
    - when the same file is added to different Kodi versions at different times, the _recency_ of the fields `last_played, play_count` is used to resolve the 
    confict across Kodi versions. For e.g. assume two Kodi versions Kodi19, Kodi20. Let's say we add a new TV show to Kodi20 and then watch a couple of epsiodes. 
    As metadata syncing is out of scope for this project, we then add the same TV show in Kodi20. The `last_played, play_count` from Kodi19 will then be synced to
    Kodi20.
    

# Known Issues/Limitations/Gotchas
- Syncing behaviour of the `files` table across version is WIP. Your mileage may vary. 
- Only one user per Kodi database is supported at the moment. You can't sync multiple users in your Kodi database across versions.
- Since a file is defined by its full filesystem path (absolute file paths), the same file across different filesystems are treated as different files. This problem is non-existent when using network file paths such as smb or nfs.

# Support
- Open up an issue or ask on the Kodi forum and please be patient. I will try my best to answer in a reasonable time frame :) 

# The How
To be specific, we seek to sync the contents of
[bookmark](https://kodi.wiki/view/Databases/MyVideos#bookmark) (where `type` = 1), [files](https://kodi.wiki/view/Databases/MyVideos#files),
and [settings](https://kodi.wiki/view/Databases/MyVideos#settings) tables across Kodi versions. 
I believe these tables essentially contain information independent of the metadata fetched from scrapers.

# Contribute
- [Commit guidelines](https://www.conventionalcommits.org/en/v1.0.0/)

- [ ] Add a show in Kodi a. Watch an episode, change some setting and bookmarks for another episode. Then add the same show in Kodi b. See if the play count, settings, bookmarks sync. 
- Kodi 18. Permanent Roommates. watch s01e01. id_file=1021 in kodi 18. now start s01e02 around 4m bookmark. turn off subs. id_file=1507 in kodi 20. last_played is NULL.
The last_played got cleared in Kodi 18 from Kodi 20. That is incorrect. I watched it in Kodi 18 first. This should've been updated. The bookmark is there in Kodi 20 for s01e02 at 4:02
Mark it as watched in kodi 20 first. This works. In kodi 18 it is last_played.
- Try again with Tripling. Kodi 18. s01e01 id_file=1042, id_path=86. In KodiFileSync.files created_at=2024-02-20 09:00:52, updated_at=2024-02-20 09:00:53. Why is there an updated_at non-null field?
This would explain the case above with Permanent roommates. The reason is because of Kodi itself
```
2024-02-20 09:00:52.700 T:8128   DEBUG: Mysql execute: insert into files (idFile, idPath, strFileName) values(NULL, 86, 'Tripling.S01E01.Toh.Chalein..1080p.ZEE5.WEB-DL.AAC2.0.H.264-DTR.mkv')
2024-02-20 09:00:52.994 T:8128   DEBUG: Mysql execute: UPDATE files SET dateAdded='2023-06-01 22:57:48' WHERE idFile=1042
```

- try again after the fix. add tvf pitchers
```
2024-02-21 00:13:02.322 T:10028   DEBUG: VideoInfoScanner: Adding new item to tvshows:nfs://192.168.0.11/mnt/mannvol/Videos/IndianTVShows/TVF Pitchers/Season 01/Pitchers.S01E01.Tu.Beer.Hai.1080p.ZEE5.WEB-DL.AAC2.0.H.264-DTR.mkv
2024-02-21 00:13:02.386 T:10028   DEBUG: Mysql execute: insert into files (idFile, idPath, strFileName) values(NULL, 90, 'Pitchers.S01E01.Tu.Beer.Hai.1080p.ZEE5.WEB-DL.AAC2.0.H.264-DTR.mkv')
2024-02-21 00:13:02.699 T:10028   DEBUG: Mysql execute: UPDATE files SET dateAdded='2023-06-01 23:18:04' WHERE idFile=1057
2024-02-21 00:13:02.807 T:10028   ERROR: SQL: [MyVideos116] Undefined MySQL error: Code (1054)
                                            Query: UPDATE files SET dateAdded='2023-06-01 23:18:04' WHERE idFile=1057
```

- update to BEFORE UPDATE. From AFTER update. TRY AGIAN NOT WORKING. THe updated_at field is populated for some reason on an initial import

```
2024-02-22 22:05:30.030 T:2776   DEBUG: Mysql execute: insert into files (idFile, idPath, strFileName) values(NULL, 111, 'Game.of.Thrones.S01.E01.1080p.BluRay.DTS.x264-ESiR.mkv')
2024-02-22 22:05:30.458 T:2776   DEBUG: Mysql execute: UPDATE files SET dateAdded='2015-07-20 18:00:50' WHERE idFile=1142
2024-02-22 22:05:31.466 T:2776   DEBUG: Mysql execute: update files set playCount=NULL,lastPlayed=NULL where idFile=1142
```
THis is it. There is another update statement I missed!