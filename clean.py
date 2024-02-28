# Clean the database and triggers associated with this file syncing
"""
This script facilitates cleaning up the database and triggers used to 
keep your bookmarks, files, settings in sync across Kodi versions
"""

import logging
import time
import mysql.connector
import os
import yaml
import time

from jinja2 import Environment, FileSystemLoader
from dotenv import load_dotenv
from tqdm import tqdm


# Set up logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
# logger.setLevel(logging.DEBUG)
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
        logger.info(f"Failed to execute {query}")
        logger.info(f"Error in executing query: {err}")
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

db_sync = run_config["db_sync"]    
kodi_dbs = run_config["kodi_dbs"]

assert (len(kodi_dbs) > 1), "Only one Kodi database provided in config.yaml file. Please specify two or more Kodi databases to clean"

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


# 1. Drop triggers in Kodi databases
for version, db_kodi in kodi_dbs:
    # 3. Triggers in Kodi versions
    execute_sql_template(environment, cursor,
                        "drop-triggers.sql",
                        {"db_kodi": db_kodi, "kodi_version": version},
                        f"Dropping Kodi-File-Sync related Triggers in {db_kodi}",
                        ";") 

# 2. Drop database
execute_sql_template(environment, cursor,
                        "drop-database.sql",
                        {"db_name": db_sync},
                        f"Dropping database {db_sync}")