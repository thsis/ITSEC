import os
import powerlaw
import networkx as nx
import numpy as np
import pandas as pd
from matplotlib import pyplot as plt
from matplotlib.ticker import FormatStrFormatter

data_path = os.path.join(".", "data", "ethereum-data.zip")
general_data_path = os.path.join(".", "data", "export-EtherPrice.csv")
outdir = os.path.join(".", "analysis")

# Load custom dataset
data = pd.read_csv(data_path)
data.inception_time = pd.to_datetime(data.inception_time,
                                     unit="s")

data["day"] = data.inception_time.dt.date
# Convert to ether
data["value"] = data["value"] / 10**18
#data["gas_used"] = data["gas_used"] / 10**18
#data["gas_price"] = data["gas_price"] / 10**18

# Load general dataset
general_data = pd.read_csv(general_data_path,
                           names=["date", "timestamp", "val"], skiprows=[0])
general_data.date = pd.to_datetime(general_data.date)
general_data["day"] = general_data.date.dt.date

# Merge dataframes
data = pd.merge(data, general_data, how="left", on="day")
data.columns
data.agg({"block_hash": "nunique", "tx_hash": "nunique"})

senders = set(data.sender)
receivers = set(data.receiver)

tx_dist = data.sender.value_counts().value_counts(normalize=True)[:10]
breaks = tx_dist.iloc[[0, 2, 3, 9]]

fig, ax = plt.subplots(1)
tx_dist.plot.bar(color="red", ax=ax, rot=0)
ax.set_ylabel("Percentage of wallets")
ax.set_xlabel("Total transactions")
ax.set_yticks(breaks)
ax.yaxis.set_major_formatter(FormatStrFormatter('%.2f'))
ax.hlines(breaks, xmin=-10, xmax=10, color="white", linewidth=1, alpha=1)
ax.set_xlim([-0.5, 9.5])
plt.tight_layout()
fig.savefig(os.path.join("pics", "distribution.png"))
plt.clf()
# Descriptive statistics for custom dataset
desc_cols = ["sender", "receiver", "value", "gas_used", "gas_price"]
desc = data[desc_cols].describe().round(2).iloc[1:, :]
desc.columns = ["value", "gas used", "gas price"]

# Round data and add num users/receivers/senders
desc.to_latex(os.path.join(outdir, "descriptive.tex"))
desc.to_csv(os.path.join(outdir, "descriptive.csv"), index=False)

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

fig, ax = plt.subplots(1, figsize=(15, 15))
sample = interactor_data.sample(2000)
G = nx.from_pandas_edgelist(df=sample,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=sample.sender.tolist())
nx.draw(G, with_labels=False, ax=ax)
fig.savefig(os.path.join(outdir, "graph-subsample-1000.png"))

fig, ax = plt.subplots(1, figsize=(20, 20))
G = nx.from_pandas_edgelist(df=interactor_data,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=interactor_data.sender.tolist())
nx.draw(G, with_labels=False, ax=ax)
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
edges["C_out"] = 2*edges["triangles"]/(edges["outgoing"]*(edges["outgoing"]-1))
edges["C_total"] = 2*edges["triangles"] / (edges["total"]*(edges["total"]-1))

edges.replace([np.inf, np.nan], 0, inplace=True)
avg_cluster = edges[["C_in", "C_out", "C_total"]].mean()

edges.C_in.plot(kind="hist")
edges.C_out.plot(kind="density", ylim=(0, 1))
edges.C_total.plot(kind="density")
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
avg_cluster
avg_cluster.to_latex()

deg_cent = nx.degree_centrality(G)
bet_deg_cent = nx.betweenness_centrality(G)
closeness_cent = nx.closeness_centrality(G)
node_clustering = nx.clustering(G)

avg_clustering = nx.average_clustering(G)


centrality = pd.DataFrame({
    "degree centrality": deg_cent,
    "betweenness centrality": bet_deg_cent,
    "closeness centrality": closeness_cent,
    "local clustering": node_clustering
})
