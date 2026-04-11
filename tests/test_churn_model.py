"""
Unit tests for the Streamify churn model.
All tests use synthetic data — no SQL Server connection required.
"""

import numpy as np
import pandas as pd
import pytest
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split

# =============================================================================
# SYNTHETIC DATA
# =============================================================================
FEATURES = [
    "total_sessions", "avg_watch_time", "completion_rate",
    "avg_rating", "total_pauses", "had_upgrade",
    "had_downgrade", "had_failed_payment"
]

def make_data(n: int = 200) -> pd.DataFrame:
    np.random.seed(42)
    return pd.DataFrame({
        "total_sessions":     np.random.randint(1, 50, n),
        "avg_watch_time":     np.random.uniform(5, 120, n),
        "completion_rate":    np.random.uniform(0, 1, n),
        "avg_rating":         np.random.uniform(1, 5, n),
        "total_pauses":       np.random.randint(0, 20, n),
        "had_upgrade":        np.random.randint(0, 2, n),
        "had_downgrade":      np.random.randint(0, 2, n),
        "had_failed_payment": np.random.randint(0, 2, n),
        "is_churn":           np.random.randint(0, 2, n),
    })

# =============================================================================
# TESTS
# =============================================================================
def test_data_shape():
    df = make_data()
    assert len(df) == 200
    assert "is_churn" in df.columns

def test_no_missing_values():
    df = make_data()
    assert df[FEATURES + ["is_churn"]].isnull().sum().sum() == 0

def test_model_trains():
    df = make_data()
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(df[FEATURES], df["is_churn"])
    assert hasattr(model, "feature_importances_")

def test_model_accuracy():
    df = make_data(500)
    X_train, X_test, y_train, y_test = train_test_split(
        df[FEATURES], df["is_churn"], test_size=0.2, random_state=42
    )
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X_train, y_train)
    acc = accuracy_score(y_test, model.predict(X_test))
    assert acc >= 0.50, f"Accuracy too low: {acc:.4f}"

def test_prediction_output():
    df = make_data()
    model = RandomForestClassifier(n_estimators=10, random_state=42)
    model.fit(df[FEATURES], df["is_churn"])
    preds = model.predict(df[FEATURES][:5])
    assert set(preds).issubset({0, 1})
