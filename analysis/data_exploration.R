if(!require("data.table")) install.packages("data.table"); library("data.table")
if(!require("dplyr")) install.packages("dplyr"); library("dplyr")
if(!require("lubridate")) install.packages("lubridate"); library("lubridate")

# Data transformations
dt <- read.csv("data/ethereum_data.csv", colClasses = "character")
dt[c("block_hash", "tx_hash", "sender", "receiver")] <- lapply(dt[c("block_hash", "tx_hash", "sender", "receiver")], as.factor)
dt[c("block_bas", "gas_limit", "inception_time", "value", "gas_used", "gas_price")] <- lapply(dt[c("block_bas", "gas_limit", "inception_time", "value", "gas_used", "gas_price")], as.numeric)
dt$inception_time <- as.POSIXct(dt$inception_time, origin="1970-01-01")
dt <- data.table(dt)


# Data description
summary(dt)
tx_n <- nrow(dt)
tx_volume <- sum(dt$value, na.rm = TRUE)
tx_average_value <- tx_n/tx_volume
tx_n; tx_volume; tx_average_value

# blocks_n <- length(unique(unlist(dt$block_hash)))
# average_tx_per_block <- tx_n/blocks_n
# average_tx_volume_per_block <- tx_volume/blocks_n

block_descriptives <- dt %>%
  group_by(block_hash) %>%
  summarize(block_tx=n(), block_tx_perc=n()/tx_n*100, block_volume=sum(value), 
            block_volume_perc=sum(value)/tx_volume*100, block_average_tx_value=mean(value)) %>%
  arrange(desc(block_tx))
summary(block_descriptives)

tx_descriptives <- dt %>%
  group_by(inception_time) %>%
  summarize(tx_n=n(), tx_perc=n()/tx_n*100, tx_volume=sum(value), 
            tx_volume_perc=sum(value)/tx_volume*100, tx_average_value=mean(value)) %>%
  arrange(desc(tx_n))
summary(tx_descriptives)


major_senders <- dt %>%
  group_by(sender) %>%
  summarize(sender_tx=n(), sender_tx_perc=n()/tx_n*100, sender_volume=-sum(value), 
            sender_volume_perc=-sum(value)/tx_volume*100, sender_average_value=-mean(value)) %>%
  arrange(desc(sender_tx))
colnames(major_senders)[1] <- "wallet"
summary(major_senders)


major_receivers <- dt %>%
  group_by(receiver) %>%
  summarize(receiver_tx=n(), receiver_tx_perc=n()/tx_n*100, receiver_volume=sum(value), 
            receiver_volume_perc=sum(value)/tx_volume*100, receiver_average_value=mean(value)) %>%
  arrange(desc(receiver_tx))
colnames(major_receivers)[1] <- "wallet"
summary(major_receivers)


major_senders <- data.table(major_senders)
major_receivers <- data.table(major_receivers)
setkey(major_receivers,wallet)
setkey(major_senders,wallet)
broad_data <- merge(major_senders,major_receivers, all = TRUE)

a <- unlist(broad_data$wallet)
nrow(broad_data) == length(a)


# List of Nodes and edges
nodes <- data.table(a)
colnames(nodes) <- "Nodes"

edges <- data.table(dt[,c("sender","receiver")])
edges <- edges[edges$sender != "",]
colnames(edges) <- c("Source", "Target")

write.csv(nodes,"data/nodes.csv")
write.csv(edges,"data/edges.csv")

# Furthe inspiration
order_weekday_abs <- train_broad_data[order ==1, NROW(lineID), by = list(weekday)]
