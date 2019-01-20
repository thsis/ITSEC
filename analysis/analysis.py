import os
import networkx as nx
import numpy as np
import pandas as pd
from scipy.stats import pearsonr
from matplotlib import pyplot as plt


data_path = os.path.join(".", "data", "ethereum_data.csv")
general_data_path = os.path.join(".", "data", "export-EtherPrice.csv")
outdir = os.path.join(".", "data")

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
n_transactions = users.user.value_counts()
major_players = n_transactions[n_transactions > 2000].index.values.tolist()
data["is_major_sender"] = data.sender.isin(major_players)
data["is_major_receiver"] = data.receiver.isin(major_players)

graph_data = data[data.is_major_sender | data.is_major_receiver]
sample = graph_data.sample(1500)

G = nx.from_pandas_edgelist(df=sample[["sender", "receiver", "value"]],
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=sample.sender.tolist())
nx.draw(G, with_labels=False)

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

degrees = interactor_data.receiver.value_counts() +
degrees.sum()


degrees_receiver = interactor_data.receiver.value_counts()
degrees_sender = interactor_data.sender.value_counts()

degrees_sender.shape
degrees_receiver.shape

(degrees_sender + degrees_receiver)
intersection



fig, ax = plt.subplots(1, figsize=(15, 15))
G = nx.from_pandas_edgelist(df=interactor_data,
                            source="sender",
                            target="receiver",
                            edge_attr="value")
G.add_nodes_from(nodes_for_adding=interactor_data.sender.tolist())
nx.draw(G, with_labels=False, ax=ax)
ax.set_title("Graph of all Interactors")
