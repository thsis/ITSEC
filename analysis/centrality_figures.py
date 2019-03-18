"""
Create figures for Centrality Measures.
"""

import os
import pandas as pd
from matplotlib import pyplot as plt

data_path = os.path.join("analysis", "centrality_100000.csv")

data = pd.read_csv(data_path, index_col=[0])

data.shape
data.columns = data.columns.str.capitalize()
desc = data.describe().iloc[1:, :].round(4)
desc.to_latex(os.path.join("analysis", "centrality.tex"))

fig, axes = plt.subplots(2, 2)
for col, ax in zip(data.columns, axes.flatten()):
    data[col].plot.box(ax=ax)

fig.savefig(os.path.join("analysis", "centrality.png"))
