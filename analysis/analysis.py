import os
import powerlaw
import networkx as nx
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt


data_path = os.path.join(".", "data", "ethereum_data.csv")
general_data_path = os.path.join(".", "data", "export-EtherPrice.csv")
outdir = os.path.join(".", "analysis")

# Load custom dataset
data = pd.read_csv(data_path)
data.inception_time = pd.to_datetime(data.inception_time,
                                     unit="s")
data["day"] = data.inception_time.dt.date
# Load general dataset
general_data = pd.read_csv(general_data_path,
                           names=["date", "timestamp", "val"], skiprows=[0])
general_data.date = pd.to_datetime(general_data.date)
general_data["day"] = general_data.date.dt.date

# Merge dataframes
data = pd.merge(data, general_data, how="left", on="day")

# Descriptive statistics for custom dataset
desc_cols = ["sender", "receiver", "value", "gas_used", "gas_price"]
desc = data[desc_cols].describe()

# Round data and add num users/receivers/senders

desc.T.to_latex(os.path.join(outdir, "descriptive.tex"))
desc.T.to_csv(os.path.join(outdir, "descriptive.csv"), index=False)

daily = data.groupby("day").aggregate({"sender": "nunique",
                                       "receiver": "nunique",
                                       "value": [np.mean, np.median, np.std],
                                       "val": "mean"})

receivers = data.loc[:, ["receiver", "day"]]
receivers.columns = ["user", "day"]
senders = data.loc[:, ["sender", "day"]]
senders.columns = ["user", "day"]

users = pd.concat([receivers, senders])
daily["users"] = users.groupby("day").user.nunique()
daily = daily[["sender", "receiver", "users", "value", "val"]]

# =============================================================================
# Draw the graph
sender = set(data.sender.values)
receiver = set(data.receiver.values)
interactors = sender.intersection(receiver)

loc = data.sender.isin(interactors) & data.receiver.isin(interactors)
interactor_data = data.loc[loc, ["sender", "receiver", "value"]]

sample = interactor_data.sample(10000)
G = nx.from_pandas_edgelist(df=sample,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=sample.sender.tolist())
nx.draw(G, with_labels=False)

fig, ax = plt.subplots(1, figsize=(15, 15))
sample = interactor_data.sample(2000)
G = nx.from_pandas_edgelist(df=sample,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=sample.sender.tolist())
nx.draw(G, with_labels=False, ax=ax)
ax.set_title("Graph of 1000 randomly drawn Interactors")
fig.savefig(os.path.join(outdir, "graph-subsample-1000.png"))

fig, ax = plt.subplots(1, figsize=(15, 15))
G = nx.from_pandas_edgelist(df=interactor_data,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=interactor_data.sender.tolist())
nx.draw(G, with_labels=False, ax=ax)
ax.set_title("Graph of all Interactors")
fig.savefig(os.path.join(outdir, "graph-full.png"))

# Calculate Network metrics
idx = pd.Index(interactors)
outgoing = interactor_data.sender.value_counts().reindex(idx, fill_value=0)
ingoing = interactor_data.receiver.value_counts().reindex(idx, fill_value=0)

edges = pd.concat([outgoing.rename("outgoing"), ingoing.rename("ingoing")],
                  axis=1, levels=["ingoing", "outgoing"])
edges["total"] = outgoing + ingoing

# Centrality
triangles = nx.triangles(G)
edges["triangles"] = pd.Series(triangles).reindex(idx, fill_value=0)
edges["C_in"] = 2*edges["triangles"] / (edges["ingoing"]*(edges["ingoing"]-1))
edges["C_out"] = 2*edges["triangles"] / (edges["outgoing"]*(edges["outgoing"]-1))
edges["C_total"] = 2*edges["triangles"] / (edges["total"]*(edges["total"]-1))

avg_cluster = edges[["C_in", "C_out", "C_total"]].replace(np.inf, 0).fillna(0).mean()

# Fit power law
fig, ax = plt.subplots(1)


def plot_dist(data, ax):
    """Compare theoretical and empirical powerlaw distribution."""
    data = data[data > 0]
    fit = powerlaw.Fit(data, discrete=True)
    fit.plot_pdf(color='b', linewidth=2, ax=ax, label="PDF")
    fit.power_law.plot_pdf(color='b', linestyle="--", ax=ax,
                           label="Power Law fit PDF")

    fit.plot_ccdf(color='r', linewidth=2, ax=ax, label="CCDF")
    fit.power_law.plot_ccdf(color='r', linestyle="--", ax=ax,
                            label="Power Law fit CCDF")

    ax.set_ylabel(r"p")
    ax.legend(loc="lower left")


fig, axes = plt.subplots(ncols=3, figsize=(20, 5))
titles = ["Transactions sent", "Transactions received", "Total transactions"]
datalist = [edges.outgoing, edges.ingoing, edges.total]
for title, ax, data in zip(titles, axes, datalist):
    plot_dist(data.values, ax)
    ax.set_title(title)

fig.savefig(os.path.join(outdir, "power-law-fit.png"))

# Playground Area
# Degree centrality
deg_cent = nx.degree_centrality(G)
edges["deg_centrality"] = pd.Series(deg_cent).reindex(idx)

# Between centrality
bet_cent = nx.betweenness_centrality(G)
edges["betw_centrality"] = pd.Series(bet_cent).reindex(idx)
