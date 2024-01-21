# Setup the databse for bookmark and settings syncing
"""
This script facilitates setting up the database related stuff to 
keep your bookmarks, files, settings in sync across Kodi versions
"""

import logging
import time
import mysql.connector
import os
import yaml

from jinja2 import Environment, FileSystemLoader
from dotenv import load_dotenv
from tqdm import tqdm


# Set up logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")

# Log to console
handler = logging.StreamHandler()
handler.setFormatter(formatter)
logger.addHandler(handler)

# Also log to a file
file_handler = logging.FileHandler("cpy-errors.log")
file_handler.setFormatter(formatter)
logger.addHandler(file_handler) 

# Import env variables
load_dotenv()

# Reference https://dev.mysql.com/doc/connector-python/en/connector-python-example-connecting.html
def connect_to_mysql(config, attempts=3, delay=2):
    """Connect to a MySQL server given its server parameters."""

    attempt = 1
    # Implement a reconnection routine
    while attempt < attempts + 1:
        try:
            return mysql.connector.connect(**config)
        except (mysql.connector.Error, IOError) as err:
            if (attempts is attempt):
                # Attempts to reconnect failed; returning None
                logger.info(f"Failed to connect, exiting without a connection: {err}", err)
                return None
            logger.info(f"Connection failed: {err}. Retrying ({attempt}/{attempts-1})...")
            # progressive reconnect delay
            time.sleep(delay ** attempt)
            attempt += 1
    return None

def execute_query(cursor, query: str):
    """Given a cursor object, execute a query in MySQL server"""
    try:
        logger.debug(f"Executing query {query}")
        cursor.execute(query)
    except mysql.connector.Error as err:
        logger.info(f"Failed to execute query: {err}")
        exit(1)


sql_config = {
    "host": os.getenv("MYSQL_HOST"),
    "user": os.getenv("MYSQL_USER"),
    "password": os.getenv("MYSQL_PASSWORD"),
    "port": os.getenv("MYSQL_PORT"),
}

# run config 
with open("config.yaml", "r") as f:
    run_config = yaml.full_load(f)


cnx = connect_to_mysql(sql_config)
cursor = cnx.cursor()


# db_sync = "KodiFileSync"
db_sync = run_config["db_sync"]    
# kodi_dbs = [(19, "MyVideos119"), (20, "MyVideos121")]
kodi_dbs = run_config["kodi_dbs"]

assert (len(kodi_dbs) > 1), "Only one Kodi database provided in config.yaml file. Please specify two or more Kodi databases to sync across"

environment = Environment(loader=FileSystemLoader("templates"))

def execute_sql_template(jinja_env, 
                         sql_cursor,
                         template_fname: str, 
                         render_vars: dict,
                         pbar_desc="Executing queries",
                         delimiter=";"):
    template = jinja_env.get_template(template_fname)
    queries = template.render(**render_vars)
    for query in tqdm(queries.split(delimiter), desc=pbar_desc):
        execute_query(sql_cursor, query)
    return None


# 1. Create database
if run_config["steps"]["create_sync_database"] is True: 
    execute_sql_template(environment, cursor,
                        "create-database.sql",
                        {"db_name": db_sync},
                        f"Creating database {db_sync}")
else:
    logger.info(f"Skip creating database {db_sync}")

# 2 Create triggers 
if run_config["steps"]["create_triggers"] is True:    
    execute_sql_template(environment, cursor,
                        "triggers-create-settings-and-bookmarks-from-files-inserts-into-database.sql",
                        {"db_name": db_sync},
                        f"Creating Triggers in {db_sync}")

    for version, db_kodi in kodi_dbs:
        # 3. Triggers in Kodi versions
        execute_sql_template(environment, cursor,
                            "trigger-push-inserts-into-database.sql",
                            {"db_kodi": db_kodi, "db_sync": db_sync, 
                            "kodi_version": version},
                            f"Creating Insert Triggers in {db_kodi}",
                            "//") 
        
        execute_sql_template(environment, cursor,
                            "trigger-push-updates-into-database.sql",
                            {"db_kodi": db_kodi, "db_sync": db_sync,
                            "kodi_version": version},
                            f"Creating Update Triggers in {db_kodi}",
                            ";")
        
        execute_sql_template(environment, cursor,
                            "trigger-push-deletes-into-database.sql",
                            {"db_kodi": db_kodi, "db_sync": db_sync,
                            "kodi_version": version},
                            f"Creating Delete Triggers in {db_kodi}",
                            "//")
else:
    logger.info(f"Skip creating triggers in {db_sync} and {kodi_dbs}")

# 3. Push inserts
if run_config["steps"]["push_inserts"] is True:        
    for version, db_kodi in kodi_dbs:
        # 2. Bulk inserts in database from Kodi dbs
        execute_sql_template(environment, cursor,
                            "insert-into-database.sql",
                            {"db_kodi": db_kodi, "db_sync": db_sync,
                            "kodi_version": version},
                            f"Inserting Data from {db_kodi} to {db_sync}",
                            ";")
else:
    logger.info(f"Skip inserting data from {kodi_dbs} to {db_sync}")

# 4. Create views
if run_config["steps"]["create_views"] is True:   
    execute_sql_template(environment, cursor,
                        "create-views.sql",
                        {"db_sync": db_sync},
                        f"Creating Views in {db_sync}",
                        ";")
else:
    logger.info(f"Skip creating views in {db_sync}")

# 5. Create events
if run_config["steps"]["create_events"] is True:
    execute_sql_template(environment, cursor,
                        "create-events-link-bookmarks-files-settings.sql",
                        {"db_sync": db_sync},
                        f"Creating Linking Events in {db_sync}",
                        "//")

    for version, db_kodi in kodi_dbs:
        execute_sql_template(environment, cursor,
                            "create-events-sync-to-kodi-versions.sql",
                            {"db_kodi": db_kodi, "db_sync": db_sync, 
                            "kodi_version": version},
                        f"Creating Syncing Events in {db_sync} for {db_kodi}",
                        "//") 
else:
    logger.info(f"Skip creating events in {db_sync}")
    
cursor.close()
cnx.close()