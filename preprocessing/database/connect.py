import psycopg2
from config import config


def connect():
    """Connect to the PostgreSQL database server."""
    conn = None
    try:
        params = config()
        # Create connection.
        print("Connecting to the PostgreSQL database...")
        conn = psycopg2.connect(**params)
        # Create cursor.
        cur = conn.cursor()

        # Execute a statement
        cur.execute("SELECT version()")

        # Fetch results and display them.
        db_version = cur.fetchone()
        print("Database version:", db_version)

        # Close connections
        cur.close()

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)

    finally:
        if conn is not None:
            conn.close()
            print("Database connection closed.")


if __name__ == "__main__":
    connect()
