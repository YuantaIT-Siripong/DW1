"""
Bronze Layer Extract:  Customer Profile
Extracts from MSSQL IT view  PostgreSQL Bronze layer

Source: TempPOC.vw_customer_profile_standardized (MSSQL)
Target: bronze.customer_profile_standardized (PostgreSQL)
Strategy: Incremental load based on last_modified_ts watermark
"""

import os
import sys
import logging
from datetime import datetime
from typing import Optional, List, Tuple
import pyodbc
import psycopg2
from psycopg2.extras import execute_batch
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

os.makedirs('logs', exist_ok=True)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging. FileHandler(f'logs/bronze_extract_{datetime.now().strftime("%Y%m%d_%H%M%S")}.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

# Configuration
MSSQL_CONFIG = {
    'driver': os.getenv('MSSQL_DRIVER', '{ODBC Driver 18 for SQL Server}'),
    'server': os.getenv('MSSQL_HOST', 'mssql-server. example.com'),
    'database': os.getenv('MSSQL_DB', 'operational_db'),
    'uid': os.getenv('MSSQL_USER', 'readonly_user'),
    'pwd': os.getenv('MSSQL_PASSWORD'),
    'TrustServerCertificate': 'yes',
    'Encrypt': 'no'
}

POSTGRES_CONFIG = {
    'host': os.getenv('PG_HOST', 'localhost'),
    'port': int(os.getenv('PG_PORT', 5432)),
    'database': os.getenv('PG_DB', 'dw1'),
    'user': os.getenv('PG_USER', 'dw_etl_service'),
    'password': os. getenv('PG_PASSWORD')
}

BATCH_ID = int(datetime.now().strftime('%Y%m%d%H%M%S'))
BATCH_SIZE = int(os.getenv('BATCH_SIZE', 1000))
SOURCE_VIEW = 'dbo.vw_customer_profile_standardized'
TARGET_TABLE = 'bronze.customer_profile_standardized'


class MSSQLExtractor:
    """Extract data from MSSQL source view"""
    
    def __init__(self, config: dict):
        self.config = config
        self.conn = None
        
    def connect(self):
        """Establish MSSQL connection"""
        try: 
            conn_str = ';'.join([f'{k}={v}' for k, v in self.config.items()])
            self.conn = pyodbc. connect(conn_str, timeout=30)
            logger.info("? Connected to MSSQL source")
            return self.conn
        except Exception as e:
            logger.error(f"? MSSQL connection failed: {e}")
            raise
    
    def extract_incremental(self, last_load_ts: datetime, batch_size: int = 1000):
        """
        Extract records modified since last load timestamp
        
        Args:
            last_load_ts: Watermark timestamp from last successful load
            batch_size: Number of rows per batch
            
        Yields:
            List of tuples (row batches)
        """
        query = f"""
            SELECT 
                customer_id,
                evidence_unique_key,
                firstname,
                lastname,
                firstname_local,
                lastname_local,
                person_title,
                person_title_other,
                marital_status,
                nationality,
                nationality_other,
                occupation,
                occupation_other,
                education_level,
                education_level_other,
                business_type,
                business_type_other,
                birthdate,
                total_asset,
                monthly_income,
                income_country,
                income_country_other,
                source_of_income_list,
                purpose_of_investment_list,
                last_modified_ts
            FROM {SOURCE_VIEW}
            WHERE last_modified_ts > ? 
            ORDER BY last_modified_ts, customer_id
        """
        
        try:
            cursor = self.conn.cursor()
            cursor.execute(query, last_load_ts)
            
            total_rows = 0
            while True:
                rows = cursor. fetchmany(batch_size)
                if not rows:
                    break
                    
                total_rows += len(rows)
                logger.info(f"?? Extracted batch:  {len(rows)} rows (total: {total_rows})")
                yield rows
                
            logger.info(f"? Total extracted: {total_rows} rows")
            cursor.close()
            
        except Exception as e:
            logger. error(f"? Extract failed: {e}")
            raise
    
    def close(self):
        """Close MSSQL connection"""
        if self.conn:
            self. conn.close()
            logger. info("?? MSSQL connection closed")


class PostgresLoader:
    """Load data into PostgreSQL Bronze layer"""
    
    def __init__(self, config: dict):
        self.config = config
        self.conn = None
        
    def connect(self):
        """Establish PostgreSQL connection"""
        try:
            self.conn = psycopg2.connect(**self.config)
            self.conn.autocommit = False
            logger.info("? Connected to PostgreSQL target")
            return self.conn
        except Exception as e:
            logger. error(f"? PostgreSQL connection failed: {e}")
            raise
    
    def get_last_load_timestamp(self) -> datetime:
        """
        Get last successful load timestamp from Bronze layer
        Uses MAX(last_modified_ts) to track source changes, not load time
        
        Returns: 
            Watermark timestamp (defaults to 1900-01-01 if table empty)
        """
        query = f"""
            SELECT COALESCE(MAX(last_modified_ts), '1900-01-01':: TIMESTAMP) 
            FROM {TARGET_TABLE}
        """
        
        try:
            with self.conn.cursor() as cur:
                cur.execute(query)
                result = cur.fetchone()[0]
                logger.info(f"?? Last load timestamp: {result}")
                return result
        except Exception as e: 
            logger.warning(f"?? Could not retrieve watermark (table may not exist): {e}")
            return datetime(1900, 1, 1)
    
    def load_batch(self, rows: List[Tuple], batch_id: int):
        """
        Load batch of rows into Bronze layer
        
        Args:
            rows: List of row tuples from MSSQL
            batch_id: Unique batch identifier
        """
        insert_sql = f"""
            INSERT INTO {TARGET_TABLE} (
                customer_id,
                evidence_unique_key,
                firstname,
                lastname,
                firstname_local,
                lastname_local,
                person_title,
                person_title_other,
                marital_status,
                nationality,
                nationality_other,
                occupation,
                occupation_other,
                education_level,
                education_level_other,
                business_type,
                business_type_other,
                birthdate,
                total_asset,
                monthly_income,
                income_country,
                income_country_other,
                source_of_income_list,
                purpose_of_investment_list,
                last_modified_ts,
                _bronze_load_ts,
                _bronze_source_file,
                _bronze_batch_id
            ) VALUES (
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, CURRENT_TIMESTAMP, %s, %s
            )
            ON CONFLICT (customer_id, last_modified_ts) 
            DO NOTHING
            RETURNING customer_id
        """
        
        try:
            with self.conn. cursor() as cur:
                # Append metadata to each row
                rows_with_metadata = [
                    tuple(row) + (SOURCE_VIEW, batch_id) 
                    for row in rows
                ]
                
                # Track inserted vs conflicted rows
                inserted_count = 0
                for row_data in rows_with_metadata: 
                    cur.execute(insert_sql, row_data)
                    if cur.fetchone():  # RETURNING clause returns row if inserted
                        inserted_count += 1
                
                conflicted_count = len(rows) - inserted_count
                
                self.conn.commit()
                
                # Log results
                logger.info(f"✅ Loaded batch:  {inserted_count} rows inserted")
                if conflicted_count > 0:
                    logger.warning(f"⚠️  Skipped {conflicted_count} duplicate rows (ON CONFLICT)")
                
        except Exception as e:
            self.conn.rollback()
            logger.error(f"? Load batch failed: {e}")
            raise
    
    def close(self):
        """Close PostgreSQL connection"""
        if self.conn:
            self.conn.close()
            logger.info("?? PostgreSQL connection closed")


def main():
    """
    Main ETL process:  Extract from MSSQL  Load to PostgreSQL Bronze
    """
    logger.info("=" * 80)
    logger.info(f"?? Starting Bronze Extract - Batch ID: {BATCH_ID}")
    logger.info("=" * 80)
    
    extractor = None
    loader = None
    
    try:
        # Initialize connections
        extractor = MSSQLExtractor(MSSQL_CONFIG)
        extractor.connect()
        
        loader = PostgresLoader(POSTGRES_CONFIG)
        loader.connect()
        
        # Get watermark
        last_load_ts = loader.get_last_load_timestamp()
        logger.info(f"?? Extracting records modified after: {last_load_ts}")
        
        # Extract and load in batches
        total_loaded = 0
        for batch_rows in extractor.extract_incremental(last_load_ts, BATCH_SIZE):
            loader.load_batch(batch_rows, BATCH_ID)
            total_loaded += len(batch_rows)
        
        logger.info("=" * 80)
        logger.info(f"? Bronze extract complete - Total loaded: {total_loaded} rows")
        logger.info(f"?? Batch ID: {BATCH_ID}")
        logger.info("=" * 80)
        
        return 0
        
    except Exception as e:
        logger.error("=" * 80)
        logger.error(f"? Bronze extract FAILED: {e}")
        logger.error("=" * 80)
        return 1
        
    finally:
        # Cleanup connections
        if extractor:
            extractor.close()
        if loader:
            loader.close()


if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)