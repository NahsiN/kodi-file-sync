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


# Troubleshooting

# Known Issues/Limitations
- Only one user per Kodi database is supported at the moment. You can't sync multiple users in your Kodi database across versions.
- Since a file is defined by its full filesystem path (absolute file paths), the same file across different filesystems are treated as different files. This problem is non-existent when using network file paths such as smb or nfs.
- During the initial setup, the order of the list specified in `kodi_dbs` in `config.yaml` determines which database's contents are synced with the rest. For e.g. if 
```
kodi_dbs:
  - !!python/tuple [18, "MyVideos116"]
  - !!python/tuple [19, "MyVideos119"]
  - !!python/tuple [20, "MyVideos121"]
```
then the contents of the tables `files, bookmarks, settings` in database `MyVideos121` will be synced with the others. 

# Support
- Open up an issue or ask on the Kodi forum and please be patient. I will try my best :) 

# The How
To be specific, we seek to sync the contents of
[bookmark](https://kodi.wiki/view/Databases/MyVideos#bookmark) (where `type` = 1), [files](https://kodi.wiki/view/Databases/MyVideos#files),
and [settings](https://kodi.wiki/view/Databases/MyVideos#settings) tables across Kodi versions. 
I believe these tables essentially contain information independent of the metadata fetched from scrapers.

# Contribute
- [Commit guidelines](https://www.conventionalcommits.org/en/v1.0.0/)

- [ ] files syncing bug. updating at timestamp at insert overwrites existing files. E.g. kim's convience and play count. Also files is not syncing.