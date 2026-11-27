import os
import sqlite3
import sys

expected = os.environ["SQLITE_VERSION"]
actual = sqlite3.sqlite_version

print(f"SQLite: {actual} (expected {expected})")
if actual != expected:
    sys.exit(f"SQLite {actual} does not match {expected}")
