import sqlite3
import os

DB_NAME = "smart_blind_assistant.db"

def init_db():
    """Initializes the SQLite database with required tables."""
    conn = sqlite3.connect(DB_NAME)
    c = conn.cursor()
    
    # Create Users table
    c.execute('''CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT UNIQUE,
                    phone TEXT,
                    preferences TEXT -- JSON string for settings
                )''')
                
    # Create Known Faces table (storing encoding as BLOB)
    c.execute('''CREATE TABLE IF NOT EXISTS known_faces (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    encoding_bytes BLOB NOT NULL, -- Serialized numpy array or list
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )''')
                
    # Create Interaction Logs table
    c.execute('''CREATE TABLE IF NOT EXISTS interaction_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER,
                    interaction_type TEXT, -- voice, vision
                    content TEXT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )''')

    conn.commit()
    conn.close()
    print(f"Database {DB_NAME} initialized successfully.")

def get_db_connection():
    """Returns a connection to the SQLite database."""
    conn = sqlite3.connect(DB_NAME)
    conn.row_factory = sqlite3.Row
    return conn
