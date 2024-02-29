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
        - If a `requirements/[env]-requirements.txt` file does not exist for your python environment, then create one by running `pip-compile  --output-file requirements/{os}-{python-version}-requirements.txt` and use that.
    - Install the requriements in the virtual env by running `pip-sync requirements/linux-py3.8-requirements.txt`  
5. Modify the `config.yaml`
    - Enter the kodi version and associated Video databases you'd like to keep in sync. Refer to the [wiki](https://kodi.wiki/view/Databases) to find out the default video database names for different Kodi versions. NOTE: One line per Kodi version. Syncing multiple databases per Kodi version to another Kodi version is not yet supported.
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
    - else if multiple bookmarks exist across versions for a given file, then the order of the list specified for key `kodi_dbs` in `config.yaml` determines which bookmark is synced across versions.
    For e.g. if 
```
kodi_dbs:
  - !!python/tuple [18, "MyVideos116"]
  - !!python/tuple [19, "MyVideos119"]
  - !!python/tuple [20, "MyVideos121"]
```
then the contents of the `bookmark` table in database `MyVideos121` will be synced to the others.
- `settings`
    - if only one play setting exists across Kodi versions for a given file, then that setting is synced across versions.
    - else if multiple play settings exist across versions for a given file, then the order of the list specified for key `kodi_dbs` in `config.yaml` determines which setting is synced across versions. 
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
- Open up an issue or ask on the [Kodi forum](https://forum.kodi.tv/showthread.php?tid=376472) and please be patient. I will try my best to answer in a reasonable time frame. 🙂
- A debug log from your Kodi would be super helpful when troubleshooting an issue.
- Submit a Pull Request and try your best to adhere to these [commit guidelines](https://www.conventionalcommits.org/en/v1.0.0/)