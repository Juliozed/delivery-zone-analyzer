# data cleaning script

import pandas as pd
import numpy as np
import sys

sys.path.append("C:/work_related/delivery-zone-analyzer")
from utils.cleaning_utils import quick_check, cast_dates, fill_nulls
from sqlalchemy import create_engine

print("script started....")

# ── PATHS ──────────────────────────────────────
path = "C:/work_related/"

# ── LOAD RAW DATA ──────────────────────────────
print("Loading raw data...")

df_orders = pd.read_csv(path + "olist_orders_dataset.csv")
df_customers = pd.read_csv(path + "olist_customers_dataset.csv")
df_order_items = pd.read_csv(path + "olist_order_items_dataset.csv")
df_payments = pd.read_csv(path + "olist_order_payments_dataset.csv")
df_reviews = pd.read_csv(path + "olist_order_reviews_dataset.csv")
df_products = pd.read_csv(path + "olist_products_dataset.csv")
df_sellers = pd.read_csv(path + "olist_sellers_dataset.csv")
df_geo = pd.read_csv(path + "olist_geolocation_dataset.csv")
df_prod_english = pd.read_csv(path + "product_category_name_translation.csv")

print("✅ All tables loaded.")

# ── CLEAN ORDERS ───────────────────────────────
print("Cleaning orders...")

df_orders_clean = df_orders.copy()

date_columns = [
    "order_purchase_timestamp",
    "order_approved_at",
    "order_delivered_carrier_date",
    "order_delivered_customer_date",
    "order_estimated_delivery_date",
]

df_orders_clean = cast_dates(df_orders_clean, date_columns)
df_orders_clean = df_orders_clean[df_orders_clean["order_status"] == "delivered"]
df_orders_clean = df_orders_clean.dropna(subset=["order_delivered_customer_date"])
df_orders_clean["days_late"] = (
    df_orders_clean["order_delivered_customer_date"]
    - df_orders_clean["order_estimated_delivery_date"]
).dt.days

print(f"✅ Orders clean: {df_orders_clean.shape}")

# ── CLEAN CUSTOMERS ────────────────────────────
print("Cleaning customers...")

df_customers_clean = df_customers.copy()
df_customers_clean["customer_zip_code_prefix"] = df_customers_clean[
    "customer_zip_code_prefix"
].astype(str)

print(f"✅ Customers clean: {df_customers_clean.shape}")

# ── CLEAN ORDER ITEMS ──────────────────────────
print("Cleaning order items...")

df_order_items_clean = df_order_items.copy()
df_order_items_clean["shipping_limit_date"] = pd.to_datetime(
    df_order_items_clean["shipping_limit_date"]
)

print(f"✅ Order items clean: {df_order_items_clean.shape}")

# ── CLEAN PAYMENTS ─────────────────────────────
print("Cleaning payments...")

df_payments_clean = df_payments.copy()

print(f"✅ Payments clean: {df_payments_clean.shape}")

# ── CLEAN PRODUCTS ─────────────────────────────
print("Cleaning products...")

df_products_clean = df_products.copy()
df_products_clean = df_products_clean.dropna(subset=["product_category_name"])
df_products_clean = df_products_clean.rename(
    columns={
        "product_name_lenght": "product_name_length",
        "product_description_lenght": "product_description_length",
    }
)

print(f"✅ Products clean: {df_products_clean.shape}")

# ── CLEAN SELLERS ──────────────────────────────
print("Cleaning sellers...")

df_sellers_clean = df_sellers.copy()
df_sellers_clean["seller_zip_code_prefix"] = df_sellers_clean[
    "seller_zip_code_prefix"
].astype(str)

print(f"✅ Sellers clean: {df_sellers_clean.shape}")

# ── CLEAN REVIEWS ──────────────────────────────
print("Cleaning reviews...")

df_reviews_clean = df_reviews.copy()
df_reviews_clean["review_creation_date"] = pd.to_datetime(
    df_reviews_clean["review_creation_date"]
)
df_reviews_clean["review_answer_timestamp"] = pd.to_datetime(
    df_reviews_clean["review_answer_timestamp"]
)

print(f"✅ Reviews clean: {df_reviews_clean.shape}")

# ── CLEAN GEO ──────────────────────────────────
print("Cleaning geolocation...")

df_geo_clean = df_geo.copy()

print(f"✅ Geo clean: {df_geo_clean.shape}")

# ── MERGE INTO MASTER ──────────────────────────
print("Merging tables...")

df_master = df_orders_clean.merge(df_customers_clean, on="customer_id", how="left")
df_master = df_master.merge(df_order_items_clean, on="order_id", how="left")
df_master = df_master.merge(df_payments_clean, on="order_id", how="left")
df_master = df_master.merge(df_products_clean, on="product_id", how="left")
df_master = df_master.merge(df_sellers_clean, on="seller_id", how="left")
df_master = df_master.merge(df_prod_english, on="product_category_name", how="left")

print(f"✅ Master merged: {df_master.shape}")
# ── ADD KPI COLUMNS ────────────────────────────
print("Adding KPI columns...")

# Delivery Status
df_master["delivery_status"] = np.where(
    df_master["days_late"] > 0,
    "Late",
    np.where(df_master["days_late"] == 0, "On Time", "Early"),
)

# Breach Severity
df_master["breach_severity"] = np.where(
    df_master["days_late"] > 7,
    "Critical",
    np.where(
        df_master["days_late"] > 3,
        "Moderate",
        np.where(df_master["days_late"] > 0, "Minor", "None"),
    ),
)

# Freight Ratio
df_master["freight_ratio"] = np.where(
    df_master["payment_value"] > 0,
    round((df_master["freight_value"] / df_master["payment_value"]) * 100, 2),
    0,
)

# Freight Flag
df_master["freight_flag"] = np.where(df_master["freight_ratio"] > 100, "Review", "OK")
df_master["freight_ratio"] = np.where(
    df_master["freight_ratio"] > 100, 100, df_master["freight_ratio"]
)

# Fill product nulls
df_master["product_category_name_english"] = df_master[
    "product_category_name_english"
].fillna("Unknown")
df_master

# ── LOAD TO POSTGRESQL ─────────────────────────
print("Loading to PostgreSQL...")

engine = create_engine(
    "postgresql://postgres:Moocow420@localhost:5432/delivery_zone_analyzer"
)

df_master.to_sql("orders_master", engine, if_exists="replace", index=False)

print("✅ orders_master loaded to PostgreSQL successfully.")
print(f"Final row count: {len(df_master)}")
print("\n🎉 Pipeline complete.")
