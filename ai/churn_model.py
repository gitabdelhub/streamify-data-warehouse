"""
Churn Prediction Model — Streamify Inc.
Reads from the Gold layer and trains a Random Forest classifier.

Usage: python ai/churn_model.py
"""

import os
import pyodbc
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score
import joblib

# =============================================================================
# CONNECTION
# =============================================================================
def get_connection():
    sa_password = os.environ.get("SA_PASSWORD", "Streamify@2024")
    return pyodbc.connect(
        "DRIVER={ODBC Driver 18 for SQL Server};"
        "SERVER=localhost,1433;"
        "DATABASE=streamify;"
        f"UID=SA;PWD={sa_password};"
        "TrustServerCertificate=yes;"
    )

# =============================================================================
# DATA EXTRACTION
# =============================================================================
def load_data() -> pd.DataFrame:
    query = """
        SELECT
            fs.customer_id,
            COUNT(DISTINCT fv.session_id)               AS total_sessions,
            AVG(fv.watch_time_minutes)                  AS avg_watch_time,
            AVG(CAST(fv.is_completed AS FLOAT))         AS completion_rate,
            AVG(CAST(fv.rating      AS FLOAT))          AS avg_rating,
            SUM(CAST(fv.had_pause   AS INT))            AS total_pauses,
            MAX(fs.is_upgrade)                          AS had_upgrade,
            MAX(fs.is_downgrade)                        AS had_downgrade,
            MAX(fs.is_payment_failed)                   AS had_failed_payment,
            MAX(fs.is_churn)                            AS is_churn
        FROM gold.fact_subscriptions fs
        LEFT JOIN gold.fact_viewing_sessions fv
            ON fs.customer_id = fv.customer_id
        GROUP BY fs.customer_id
    """
    with get_connection() as conn:
        return pd.read_sql(query, conn)

# =============================================================================
# TRAINING
# =============================================================================
FEATURES = [
    "total_sessions", "avg_watch_time", "completion_rate",
    "avg_rating", "total_pauses", "had_upgrade",
    "had_downgrade", "had_failed_payment"
]

def train(df: pd.DataFrame) -> float:
    df = df.dropna(subset=FEATURES + ["is_churn"])
    X, y = df[FEATURES], df["is_churn"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    acc = accuracy_score(y_test, y_pred)

    print("=" * 50)
    print("      CHURN MODEL — STREAMIFY INC.")
    print("=" * 50)
    print(f"Accuracy : {acc:.4f}")
    print(classification_report(y_test, y_pred))

    os.makedirs("ai", exist_ok=True)
    joblib.dump(model, "ai/churn_model.pkl")
    print("Model saved: ai/churn_model.pkl")

    return acc

# =============================================================================
# MAIN
# =============================================================================
if __name__ == "__main__":
    print("Loading data from Gold layer...")
    df = load_data()
    print(f"{len(df)} customers loaded.")
    train(df)
