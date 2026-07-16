# ── BOILERPLATE: ETL PIPELINE ──────────────────
# Project: [PROJECT NAME]
# Author: Julio Cesar Zamora Ramirez
# Date: [DATE]
# Description: [WHAT THIS PIPELINE DOES]
# ───────────────────────────────────────────────

import pandas as pd
import numpy as np
import sys
from sqlalchemy import create_engine

sys.path.append("C:/work_related/[PROJECT_FOLDER]")
from utils.cleaning_utils import quick_check, cast_dates, fill_nulls

# ── CONFIG ─────────────────────────────────────
PATH = "C:/work_related/"
DB_URL = "postgresql://postgres:YOUR_PASSWORD@localhost:5432/[DATABASE_NAME]"
TABLE_NAME = "[TABLE_NAME]"

# ── EXTRACT ────────────────────────────────────
print("Extracting data...")

# df = pd.read_csv(PATH + "your_file.csv")

print("✅ Data extracted.")

# ── TRANSFORM ──────────────────────────────────
print("Transforming data...")

# df_clean = df.copy()
# cast_dates(df_clean, ["date_col1", "date_col2"])
# fill_nulls(df_clean, text_cols=["col1"], numeric_cols=["col2"])
# df_clean["new_kpi"] = np.where(df_clean["col"] > 0, "Yes", "No")

print("✅ Data transformed.")

# ── LOAD ───────────────────────────────────────
print("Loading to database...")

engine = create_engine(DB_URL)

# df_clean.to_sql(TABLE_NAME, engine, if_exists="replace", index=False)

print(f"✅ {TABLE_NAME} loaded successfully.")
print(f"Final row count: {len(df_clean)}")
print("\n🎉 Pipeline complete.")


# How to use it for any new project:

# Copy it into your new project's src folder
# Change PATH, DB_URL, TABLE_NAME at the top
# Fill in the Extract section with your CSV files
# Fill in the Transform section with your specific cleaning steps
# Run it
