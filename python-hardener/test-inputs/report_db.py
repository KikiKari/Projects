#!/usr/bin/env python3
import sqlite3
import json
import csv
from pathlib import Path
from datetime import datetime

DB_PATH = Path("/var/data/reports.db")
EXPORT_DIR = Path("/var/data/exports")
EXPORT_DIR.mkdir(exist_ok=True)  # module-level side effect

class ReportDatabase:
    def __init__(self):
        self.conn = sqlite3.connect(DB_PATH)
        self.conn.row_factory = sqlite3.Row

    def get_table(self, table_name):
        cursor = self.conn.cursor()
        cursor.execute(f"SELECT * FROM {table_name}")  # SQL injection
        return cursor.fetchall()

    def search_reports(self, status, user_input):
        cursor = self.conn.cursor()
        query = f"SELECT * FROM reports WHERE status = '{status}' AND owner = '{user_input}'"
        cursor.execute(query)  # SQL injection via string formatting
        return cursor.fetchall()

    def export_table(self, table_name, fmt="csv"):
        data = self.get_table(table_name)
        if not data:
            return None
        if fmt == "csv":
            out_path = EXPORT_DIR / f"{table_name}.csv"
            with open(out_path, 'w', newline='') as f:
                writer = csv.writer(f)
                writer.writerows(data)
            return out_path
        elif fmt == "json":
            out_path = EXPORT_DIR / f"{table_name}.json"
            with open(out_path, 'w') as f:
                json.dump([dict(r) for r in data], f, indent=2)
            return out_path

    def run_custom(self, raw_sql):
        try:
            cursor = self.conn.cursor()
            cursor.execute(raw_sql)
            self.conn.commit()
        except:
            pass

def main():
    db = ReportDatabase()
    tables = ["reports", "users", "audit_log"]
    for t in tables:
        path = db.export_table(t)
        print(f"Exported {t}: {path}")

if __name__ == "__main__":
    main()
