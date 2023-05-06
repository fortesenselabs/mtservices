import numpy as np
import pandas as pd
from typing import List
from sklearn import metrics

#
# ML Model Utils
#

def compute_scores(y_true, y_hat):
    """Compute several scores and return them as dict."""
    y_true = y_true.astype(int)
    y_hat_class = np.where(y_hat.values > 0.5, 1, 0)

    try:
        auc = metrics.roc_auc_score(y_true, y_hat.fillna(value=0))
    except ValueError:
        # Only one class is present (if dataset is too small, e.g,. when debugging) or Nulls in predictions
        auc = 0.0

    try:
        ap = metrics.average_precision_score(y_true, y_hat.fillna(value=0))
    except ValueError:
        # Only one class is present (if dataset is too small, e.g,. when debugging) or Nulls in predictions
        ap = 0.0

    f1 = metrics.f1_score(y_true, y_hat_class)
    precision = metrics.precision_score(y_true, y_hat_class)
    recall = metrics.recall_score(y_true, y_hat_class)

    scores = dict(
        auc=auc,
        ap=ap,  # it summarizes precision-recall curve, should be equivalent to auc
        f1=f1,
        precision=precision,
        recall=recall,
    )

    return scores


def double_columns(df, shifts: List[int]):
    if not shifts:
        return df
    df_list = [df.shift(shift) for shift in shifts]
    df_list.insert(0, df)
    max_shift = max(shifts)

    # Shift and add same columns
    df_out = pd.concat(df_list, axis=1)  # keys=('A', 'B')

    return df_out


# def import_string(dotted_path):
