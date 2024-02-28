# KodiFileSync 🔄
If using a central database server to manage your Kodi library, e.g. [MySQL](https://kodi.wiki/view/MySQL), 
this project aims to _sync certain video file metadata across Kodi versions_. The metadata includes 
resume type bookmarks, settings such as audio or subtitle track, play counts, last played etc.
The metadata _excludes_ information gathered from scrapers such as movie/tv show names, ratings, actors, genres etc. 


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


# The How
To be specific, we seek to sync the contents of
[bookmark](https://kodi.wiki/view/Databases/MyVideos#bookmark) (where `type` = 1), [files](https://kodi.wiki/view/Databases/MyVideos#files),
and [settings](https://kodi.wiki/view/Databases/MyVideos#settings) tables across different Kodi versions. 
I believe these tables essentially contain information that is independent of the metadata fetched from scrapers.   


# Syncing Behaviour 
In an ideal world, the ask is that the most _appropriate_ state of the bookmark, settings or files tables be synced across Kodi versions. Often 
most appropriate means the same thing as most recent but not in all cases. Below I describe how this project aims to resolve 
the conflicts that arise when these 3 tables get out of sync across different Kodi versions.

During the initial installation, the order of syncing for the different tables is defined as:
- `bookmark`
    - if only one bookmark exists across versions for a given file, then that bookmark is synced across versions.
    - else if multiple bookmarks exist across versions for a given file, then the order of the list specified in `kodi_dbs` in `config.yaml` determines which bookmark is synced across versions.
    For e.g. if 
```
kodi_dbs:
  - !!python/tuple [18, "MyVideos116"]
  - !!python/tuple [19, "MyVideos119"]
  - !!python/tuple [20, "MyVideos121"]
```
then the contents of the `bookmark` table in database `MyVideos121` will be synced to the others. Not necessarily true, e.g. with files or bookmarks.
- `settings`
    - if only one play setting exists across Kodi versions for a given file, then that setting is synced across versions.
    - else if multiple play settings exist across versions for a given file, then the order of the list specified in `kodi_dbs` in `config.yaml` determines which setting is synced across versions. 
- `files`
    - the most recent `last_played` field value resolves the conflict across Kodi versions for the same file. 

Post the initial installtion, during normal operation, the syncing is defined by
- `bookmark`
    - the most recent bookmark update is synced across versions.
    - deleting a bookmark (by either resetting resume position or finish watching the file) is synced across versions.
- `settings`
    - the most recent settings update is synced across versions.
- `files`
    - if the same file already exists in multiple versions, then the most recent updates to the file is synced across versions. 
    - when the same file is added to different Kodi versions at different times, the _recency_ of the fields `last_played, play_count` is used to resolve the 
    confict across Kodi versions. For e.g. assume two Kodi versions Kodi19, Kodi20. Let's say we add a new TV show to Kodi20 and then watch a couple of epsiodes. 
    As metadata syncing is out of scope for this project, we then add the same TV show (and its corresponding files) in Kodi20. 
    The `last_played, play_count` values from Kodi19 will then be synced to Kodi20.

 
# Known Issues/Limitations/Gotchas
- _Syncing behaviour of the `files` table across Kodi versions is a work-in-progress. Your mileage may vary._ 
- Only one user per Kodi database is supported at the moment. You can't sync multiple users in your Kodi database across versions.
- Since a file is defined by its full filesystem path (absolute file paths), the same file across different filesystems are treated as different files. 
    This problem is non-existent when using network file paths such as smb or nfs.
- Only MySQL is supported at the moment.
- The syncing is _not_ instantaneous, currently it takes anywhere between 3 to 8 minutes to propagate a change to any of the 3 tables across the different Kodi versions. 
    This will be made editable in a future versions through the `config.yaml` file.

# Uninstall
Follow similar instructions as in the **Install** section above for steps 1-5. For step 6, run `python clean.py` which will remove any triggers in Kodi databases and drop the syncing database.

# Support/Contribute/Ideas
- Open up an issue or ask on the Kodi forum and please be patient. I will try my best to answer in a reasonable time frame. 🙂
- A debug log from your Kodi would be super helpful when troubleshooting an issue.
- Submit a Pull Request and try your best to adhere to these [commit guidelines](https://www.conventionalcommits.org/en/v1.0.0/)

- [X] Talk about syncing limitations. time 3-8 minutes
- [X] clean script. remove's database
- [X] before or after update

```
2024-02-25 09:01:48.104 T:24312   DEBUG: Mysql execute: UPDATE files SET dateAdded='2023-09-12 01:51:38' WHERE idFile=461
2024-02-25 09:01:48.140 T:24312   DEBUG: This query part contains a like, we will double backslash in the next field: select actor_id from actor where name like '
2024-02-25 09:01:48.481 T:24312   DEBUG: Previous line repeats 3 times.
2024-02-25 09:01:48.481 T:24312   DEBUG: Mysql execute: UPDATE rating SET rating = 8.200000, votes = 14 WHERE rating_id = 467
2024-02-25 09:01:48.517 T:24312   DEBUG: Mysql execute: DELETE FROM uniqueid WHERE media_id=461 AND media_type='episode'
2024-02-25 09:01:48.591 T:24312   DEBUG: Mysql execute: INSERT INTO uniqueid (media_id, media_type, value, type) VALUES (461, 'episode', '779565', 'tmdb')
2024-02-25 09:01:48.664 T:24312   DEBUG: Mysql Start transaction
2024-02-25 09:01:48.664 T:24312   DEBUG: Mysql execute: DELETE FROM streamdetails WHERE idFile = 461
2024-02-25 09:01:48.700 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strVideoCodec, fVideoAspect, iVideoWidth, iVideoHeight, iVideoDuration, strStereoMode, strVideoLanguage) VALUES (461,0,'h264',1.777778,1920,1080,1437,'','eng')
2024-02-25 09:01:48.737 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (461,1,'dca',6,'eng')
2024-02-25 09:01:48.771 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (461,1,'ac3',2,'eng')
2024-02-25 09:01:48.808 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strSubtitleLanguage) VALUES (461,2,'eng')
2024-02-25 09:01:48.846 T:24312   DEBUG: Mysql execute: update movie set c11=1437 where idFile=461 and c11=''
2024-02-25 09:01:48.881 T:24312   DEBUG: Mysql execute: update episode set c09=1437 where idFile=461 and c09=''
2024-02-25 09:01:48.919 T:24312   DEBUG: Mysql execute: update musicvideo set c04=1437 where idFile=461 and c04=''
2024-02-25 09:01:49.108 T:24312   DEBUG: Mysql commit transaction
2024-02-25 09:01:49.324 T:24312   DEBUG: Mysql execute: UPDATE episode SET c00='Turning the Tides',c01='The Equalists begin their attack on Republic City.',c03='467',c04='Michael Dante DiMartino / Bryan Konietzko',c05='2012-06-16',c06='<thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/4bMT828aaNIhswrw7sWac6vby8J.jpg</thumb><thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/kk3BBUW4yCipAXVTzhWE4O0F5LL.jpg</thumb><thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/i1fiqacz2j5YDpCLwuTrswPzv6Q.jpg</thumb>',c07='',c09='1437',c10='Joaquim Dos Santos / Ki Hyun Ryu',c11='',c12='1',c13='10',c14='',c15='-1',c16='-1',c17='-1',c18='nfs://192.168.0.11/mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E10.Turning.the.Tides.Bluray-1080p.x264.DTS-D-Z0N3.mkv',c19='27',c20='1422', userrating = NULL, idSeason = 31 where idEpisode=461
2024-02-25 09:01:49.495 T:24312   DEBUG: Mysql commit transaction
2024-02-25 09:01:49.610 T:24312   DEBUG: CThumbExtractor::DoWork - trying to extract filestream details from video file nfs://192.168.0.11/mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:49.610 T:24312   DEBUG: CFileCache::Open - opening <mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv> using cache
2024-02-25 09:01:49.774 T:24312   DEBUG: CNFSFile::Open - opened mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:49.943 T:24868   DEBUG: Thread FileCache start, auto delete: false
2024-02-25 09:01:50.472 T:24312   DEBUG: CDVDDemuxFFmpeg::Open - probing detected format [matroska,webm]
2024-02-25 09:01:50.472 T:24312   DEBUG: CDVDDemuxFFmpeg::Open - avformat_find_stream_info starting
2024-02-25 09:01:50.515 T:24312   DEBUG: CDVDDemuxFFmpeg::Open - av_find_stream_info finished
2024-02-25 09:01:50.516 T:24312   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 0
2024-02-25 09:01:50.516 T:24312   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 1
2024-02-25 09:01:50.516 T:24312   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 2
2024-02-25 09:01:50.516 T:24312   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 3
2024-02-25 09:01:50.795 T:24868   DEBUG: Thread FileCache 24868 terminating
2024-02-25 09:01:50.796 T:24312   DEBUG: CNFSFile::Close closing file mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:50.831 T:24312   ERROR: Failed to close(mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv) - close call failed with "NFS: Commit failed with NFS3ERR_ACCES(-13)"
2024-02-25 09:01:51.529 T:24312   DEBUG: Mysql Start transaction
2024-02-25 09:01:51.529 T:24312   DEBUG: Mysql execute: DELETE FROM streamdetails WHERE idFile = 460
2024-02-25 09:01:51.563 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strVideoCodec, fVideoAspect, iVideoWidth, iVideoHeight, iVideoDuration, strStereoMode, strVideoLanguage) VALUES (460,0,'h264',1.777778,1920,1080,1441,'','eng')
2024-02-25 09:01:51.690 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (460,1,'dca',6,'eng')
2024-02-25 09:01:51.724 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (460,1,'ac3',2,'eng')
2024-02-25 09:01:51.760 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strSubtitleLanguage) VALUES (460,2,'eng')
2024-02-25 09:01:51.796 T:24312   DEBUG: Mysql execute: update movie set c11=1441 where idFile=460 and c11=''
2024-02-25 09:01:51.834 T:24312   DEBUG: Mysql execute: update episode set c09=1441 where idFile=460 and c09=''
2024-02-25 09:01:51.869 T:24312   DEBUG: Mysql execute: update musicvideo set c04=1441 where idFile=460 and c04=''
2024-02-25 09:01:52.068 T:24312   DEBUG: Mysql commit transaction
2024-02-25 09:01:52.213 T:24312   DEBUG: Mysql Start transaction
2024-02-25 09:01:52.214 T:24312   DEBUG: Mysql execute: UPDATE files SET dateAdded='2023-09-12 01:47:16' WHERE idFile=460
2024-02-25 09:01:52.279 T:24312   DEBUG: This query part contains a like, we will double backslash in the next field: select actor_id from actor where name like '
2024-02-25 09:01:52.613 T:24312   DEBUG: Previous line repeats 3 times.
2024-02-25 09:01:52.613 T:24312   DEBUG: Mysql execute: UPDATE rating SET rating = 8.300000, votes = 14 WHERE rating_id = 466
2024-02-25 09:01:52.649 T:24312   DEBUG: Mysql execute: DELETE FROM uniqueid WHERE media_id=460 AND media_type='episode'
2024-02-25 09:01:52.723 T:24312   DEBUG: Mysql execute: INSERT INTO uniqueid (media_id, media_type, value, type) VALUES (460, 'episode', '779564', 'tmdb')
2024-02-25 09:01:52.791 T:24312   DEBUG: Mysql Start transaction
2024-02-25 09:01:52.791 T:24312   DEBUG: Mysql execute: DELETE FROM streamdetails WHERE idFile = 460
2024-02-25 09:01:52.828 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strVideoCodec, fVideoAspect, iVideoWidth, iVideoHeight, iVideoDuration, strStereoMode, strVideoLanguage) VALUES (460,0,'h264',1.777778,1920,1080,1441,'','eng')
2024-02-25 09:01:52.865 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (460,1,'dca',6,'eng')
2024-02-25 09:01:52.901 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (460,1,'ac3',2,'eng')
2024-02-25 09:01:52.937 T:24312   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strSubtitleLanguage) VALUES (460,2,'eng')
2024-02-25 09:01:52.973 T:24312   DEBUG: Mysql execute: update movie set c11=1441 where idFile=460 and c11=''
2024-02-25 09:01:53.009 T:24312   DEBUG: Mysql execute: update episode set c09=1441 where idFile=460 and c09=''
2024-02-25 09:01:53.045 T:24312   DEBUG: Mysql execute: update musicvideo set c04=1441 where idFile=460 and c04=''
2024-02-25 09:01:53.228 T:24312   DEBUG: Mysql commit transaction
2024-02-25 09:01:53.446 T:24312   DEBUG: Mysql execute: UPDATE episode SET c00='Out of the Past',c01='After being imprisoned by Tarrlok, Korra attempts to analyze the mysterious visions she has been having. Meanwhile, Tenzin, Lin, Mako, Bolin and Asami search for Korra, having been given false information by Tarrlok.',c03='466',c04='Michael Dante DiMartino / Bryan Konietzko',c05='2012-06-09',c06='<thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/arzwQaAjumNd7zE53pf7t4VpxjI.jpg</thumb><thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/e9BgtvAnhoC3TJRzfsM5xopeMX9.jpg</thumb><thumb spoof=\"\" cache=\"\" aspect=\"thumb\">https://image.tmdb.org/t/p/original/4DwHKdv865KEIwiDPGty79ewtBM.jpg</thumb>',c07='',c09='1441',c10='Joaquim Dos Santos / Ki Hyun Ryu',c11='',c12='1',c13='9',c14='',c15='-1',c16='-1',c17='-1',c18='nfs://192.168.0.11/mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E09.Out.of.the.Past.Bluray-1080p.x264.DTS-D-Z0N3.mkv',c19='27',c20='1423', userrating = NULL, idSeason = 31 where idEpisode=460
2024-02-25 09:01:53.678 T:24312   DEBUG: Mysql commit transaction
2024-02-25 09:01:53.795 T:25428   DEBUG: CThumbExtractor::DoWork - trying to extract filestream details from video file nfs://192.168.0.11/mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E08.When.Extremes.Meet.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:53.795 T:25428   DEBUG: CFileCache::Open - opening <mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E08.When.Extremes.Meet.Bluray-1080p.x264.DTS-D-Z0N3.mkv> using cache
2024-02-25 09:01:53.964 T:25428   DEBUG: CNFSFile::Open - opened mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E08.When.Extremes.Meet.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:54.132 T:10544   DEBUG: Thread FileCache start, auto delete: false
2024-02-25 09:01:54.673 T:25428   DEBUG: CDVDDemuxFFmpeg::Open - probing detected format [matroska,webm]
2024-02-25 09:01:54.673 T:25428   DEBUG: CDVDDemuxFFmpeg::Open - avformat_find_stream_info starting
2024-02-25 09:01:54.720 T:25428   DEBUG: CDVDDemuxFFmpeg::Open - av_find_stream_info finished
2024-02-25 09:01:54.721 T:25428   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 0
2024-02-25 09:01:54.721 T:25428   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 1
2024-02-25 09:01:54.721 T:25428   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 2
2024-02-25 09:01:54.721 T:25428   DEBUG: CDVDDemuxFFmpeg::AddStream ID: 3
2024-02-25 09:01:54.979 T:10544   DEBUG: Thread FileCache 10544 terminating
2024-02-25 09:01:54.980 T:25428   DEBUG: CNFSFile::Close closing file mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E08.When.Extremes.Meet.Bluray-1080p.x264.DTS-D-Z0N3.mkv
2024-02-25 09:01:55.014 T:25428   ERROR: Failed to close(mnt/mannvol/Videos/TVShows/Finished/The Legend of Korra (2012)/Book 1. Air/The.Legend.of.Korra.S01E08.When.Extremes.Meet.Bluray-1080p.x264.DTS-D-Z0N3.mkv) - close call failed with "NFS: Commit failed with NFS3ERR_ACCES(-13)"
2024-02-25 09:01:55.637 T:25428   DEBUG: Mysql Start transaction
2024-02-25 09:01:55.637 T:25428   DEBUG: Mysql execute: DELETE FROM streamdetails WHERE idFile = 459
2024-02-25 09:01:55.672 T:25428   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strVideoCodec, fVideoAspect, iVideoWidth, iVideoHeight, iVideoDuration, strStereoMode, strVideoLanguage) VALUES (459,0,'h264',1.777778,1920,1080,1437,'','eng')
2024-02-25 09:01:55.709 T:25428   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (459,1,'dca',6,'eng')
2024-02-25 09:01:55.744 T:25428   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strAudioCodec, iAudioChannels, strAudioLanguage) VALUES (459,1,'ac3',2,'eng')
2024-02-25 09:01:55.780 T:25428   DEBUG: Mysql execute: INSERT INTO streamdetails (idFile, iStreamType, strSubtitleLanguage) VALUES (459,2,'eng')
2024-02-25 09:01:55.817 T:25428   DEBUG: Mysql execute: update movie set c11=1437 where idFile=459 and c11=''
2024-02-25 09:01:55.853 T:25428   DEBUG: Mysql execute: update episode set c09=1437 where idFile=459 and c09=''
2024-02-25 09:01:55.889 T:25428   DEBUG: Mysql execute: update musicvideo set c04=1437 where idFile=459 and c04=''
2024-02-25 09:01:56.076 T:25428   DEBUG: Mysql commit transaction
```