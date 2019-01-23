if(!require("data.table")) install.packages("data.table"); library("data.table")
if(!require("dplyr")) install.packages("dplyr"); library("dplyr")
if(!require("ggplot2")) install.packages("ggplot2"); library("ggplot2")
if(!require("lubridate")) install.packages("lubridate"); library("lubridate")
if(!require("maptools")) install.packages("maptools"); library("maptools")
if(!require("scales")) install.packages("scales"); library("scales")
# if(!require("gridExtra")) install.packages("gridExtra"); install.packages("gridExtra")
# if(!require("ggthemes")) install.packages("ggthemes"); install.packages("ggthemes")

# Data transformations
e_w_rate <- 1000000000000000000 #1 Ether equals x wei
s_w_rate <- 1000000000000 #1 Szabo equals x wei

dt <- read.csv("data/ethereum_data.csv", colClasses = "character")
colnames(dt)[colnames(dt)=="block_bas"] <- "block_gas"
dt[c("block_hash", "tx_hash", "sender", "receiver")] <- lapply(dt[c("block_hash", "tx_hash", "sender", "receiver")], as.factor)
dt[c("block_gas", "gas_limit", "inception_time", "value", "gas_used", "gas_price")] <- lapply(dt[c("block_gas", "gas_limit", "inception_time", "value", "gas_used", "gas_price")], as.numeric)
# dt[c("block_gas", "gas_limit", "value", "gas_price")] <- dt[,c("block_gas", "gas_limit", "value", "gas_price")]/1000000000000000000 # convert to ether
dt$inception_time <- as.POSIXct(dt$inception_time, origin="1970-01-01")
dt$time <- trunc(dt$inception_time, units = "hours")
dt$time <- as.POSIXct(dt$time, origin="1970-01-01")
dt[is.na(dt)] <- 0 # BE CAREFULL WITH THIS
dt$fee <- dt$gas_used*dt$gas_price

# descriptives <- data.frame()
# descriptives$mean <- median(dt[,c("value","gas_used")], na.rm = TRUE)
# median(dt$value)
dt_sum <- lapply(dt[,c("value","gas_used","gas_price", "fee")],sum)
dt_median <- lapply(dt[,c("value","gas_used","gas_price", "fee")],median)
dt_max <- lapply(dt[,c("value","gas_used","gas_price", "fee")],max)

dt <- data.table(dt)

# Data description----
summary(dt)

# Graphs

hist(dt$gas_used, col = "orange", border = "grey", main = "Distribution of Gas Used per Transaction", xlab = "Amount of Gas per Transaction", ylim = c(0,700))
boxplot(dt$gas_used, main = "Boxplot of Gas Used per Transaction", xlab = "Amount of Gas Used per Transaction")

# hist(dt$gas_price)
# boxplot(dt$gas_price)

hist(dt$fee/e_w_rate, col = "orange", border = "grey", main = "Distribution of Fee per Transaction", xlab = "Fee per Transaction, in ether", ylim = c(0,1000), breaks = 300)
boxplot(dt$fee/e_w_rate, main = "Boxplot of Fee per Transaction", xlab = "Fee Used per Transaction, in ether")

# hist(dt$block_gas, col = "blue", main = "Distribution of Gas Used within a Block", xlab = "Amount of Gas Used within a Block")
# boxplot(dt$block_gas, main = "Boxplot of Gas Used within a Block", xlab = "Amount of Gas Used within a Block")
# # CAREFULL!! THIS TAKES TX to make a calculation

hist(dt$value/e_w_rate, col = "orange", border = "grey", main = "Distribution of Value per Transaction", xlab = "Value of a Transaction, in ether", ylim = c(0,50), breaks = 100)
boxplot(dt$value/e_w_rate, main = "Boxplot of Value per Transaction", xlab = "Value of a Transaction, in ether")
# Add fee calculation

tx_n <- nrow(dt)
tx_volume <- sum(dt$value, na.rm = TRUE)
tx_average_value <- tx_n/tx_volume
tx_n; tx_volume; tx_average_value

# hist(dt$value/1000000000000000000,xlab = "Value of a TX", main="Distribution of TXs values", col = "green",border = "red", xlim = c(0,max(dt$value/1000000000000000000, na.rm = TRUE)), ylim = c(0,100), breaks = 100)
# summary(dt[,c("value","gas_used")])


# dt_info <- matrix(nrow = 2, ncol=3)
# colnames(dt_info) <- c('period','tx_n', 'tx_volume')
# dt_info <- as.table(dt_info)


# blocks_n <- length(unique(unlist(dt$block_hash)))
# average_tx_per_block <- tx_n/blocks_n
# average_tx_volume_per_block <- tx_volume/blocks_n


block_descriptives <- dt %>%
  group_by(block_hash) %>%
  summarize(block_tx=n(), block_tx_perc=n()/tx_n*100, block_volume=sum(value), 
            block_volume_perc=sum(value)/tx_volume*100, block_average_tx_value=mean(value)) %>%
  arrange(desc(block_tx))
summary(block_descriptives)

dt_sum$block_tx <- sum(block_descriptives$block_tx)
dt_sum$block_volume <- sum(block_descriptives$block_volume)

dt_median$block_tx <- median(block_descriptives$block_tx)
dt_median$block_volume <- median(block_descriptives$block_volume)

dt_max$block_tx <- max(block_descriptives$block_tx)
dt_max$block_volume <- max(block_descriptives$block_volume)

hist(block_descriptives$block_tx, col = "orange", border = "grey", main = "Distribution of Transactions' Number per Block", xlab = "Number of a Transactions", ylim = c(0,1000))
hist(block_descriptives$block_volume/e_w_rate, col = "orange", border = "grey", main = "Distribution of Transactions' Volume per Block", xlab = "Volume of a Transactions, in ether", ylim = c(0,50), breaks = 100)
# boxplot(block_descriptives)


time_descriptives <- dt %>%
  group_by(time) %>%
  summarize(tx_number=n(), tx_perc=n()/tx_n*100, tx_vol=sum(value, na.rm = TRUE), 
            tx_vol_perc=sum(value, na.rm = TRUE)/tx_volume*100, tx_average_value=mean(value, na.rm = TRUE)) %>%
  arrange(desc(time))
summary(time_descriptives)

dt_sum$tx_number <- sum(time_descriptives$tx_number)
dt_sum$tx_volume <- sum(time_descriptives$tx_vol)

dt_median$tx_number <- median(time_descriptives$tx_number)
dt_median$tx_volume <- median(time_descriptives$tx_vol)

dt_max$tx_number <- max(time_descriptives$tx_number)
dt_max$tx_volume <- max(time_descriptives$tx_vol)

ggplot(time_descriptives,aes(time,tx_number,group=1))+ theme_bw() + geom_point()+
  scale_x_datetime(labels = date_format("%d:%m; %H")) +
  theme(axis.text.x = element_text(angle=90,hjust=1)) 

ggplot(data=time_descriptives,aes(x=time, y=tx_number)) + 
  geom_line(colour="blue") + 
  ggtitle("Number of Transactions over Time") +
  ylab("TXs #") + 
  xlab("Time")

ggplot(data=time_descriptives,aes(x=time, y=tx_vol/e_w_rate)) + 
  geom_line(colour="blue") + 
  ggtitle("Volume of Transactions over Time, in ether") +
  ylab("TXs #") + 
  xlab("Time")


# Major wallets
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
m_w <- merge(major_senders,major_receivers, all = TRUE)
m_w[is.na(m_w)] <- 0
m_w$number_tx <- m_w$sender_tx + m_w$receiver_tx
m_w$vol_tx <- -m_w$sender_volume + m_w$receiver_volume
m_w$balance <- m_w$sender_volume + m_w$receiver_volume
summary(m_w)


top50_sender_tx <- head(m_w[order(-sender_tx),c("wallet","sender_tx")], 50)
top50_sender_tx$cum <- cumsum(top50_sender_tx$sender_tx)
top50_sender_tx$perc <- top50_sender_tx$cum/tx_n*100
plot(top50_sender_tx$perc, ylim = c(0,100), main = "Cumulative % of TXs' Number covered by Major Senders", xlab = "Top 50 Senders", ylab = "Percentage of all Transactions Number")

top50_receiver_tx <- head(m_w[order(-receiver_tx),c("wallet","receiver_tx")], 50)
top50_receiver_tx$cum <- cumsum(top50_receiver_tx$receiver_tx)
top50_receiver_tx$perc <- top50_receiver_tx$cum/tx_n*100
plot(top50_receiver_tx$perc, ylim = c(0,100), main = "Cumulative % of TXs' Number covered by Major Receivers", xlab = "Top 50 Receivers", ylab = "Percentage of all Transactions Number")

top50_sender_volume <- head(m_w[order(sender_volume),c("wallet","sender_volume")], 50)
top50_sender_volume$cum <- -cumsum(top50_sender_volume$sender_volume)
top50_sender_volume$perc <- top50_sender_volume$cum/tx_volume*100
plot(top50_sender_volume$perc, ylim = c(0,100), main = "Cumulative % of TXs' Volume covered by Major Senders", xlab = "Top 50 Senders", ylab = "Percentage of all Transactions Volume")

top50_receiver_volume <- head(m_w[order(-receiver_volume),c("wallet","receiver_volume")], 50)
top50_receiver_volume$cum <- cumsum(top50_receiver_volume$receiver_volume)
top50_receiver_volume$perc <- top50_receiver_volume$cum/tx_volume*100
plot(top50_receiver_volume$perc, ylim = c(0,100), main = "Cumulative % of TXs' Volume covered by Major Receivers", xlab = "Top 50 Receivers", ylab = "Percentage of all Transactions Volume")

top50_wallet_tx <- head(m_w[order(-number_tx),c("wallet","number_tx")], 50)
top50_wallet_tx$cum <- cumsum(top50_wallet_tx$number_tx)
top50_wallet_tx$perc <- top50_wallet_tx$cum/tx_n*100/2
plot(top50_wallet_tx$perc, ylim = c(0,100), main = "Cumulative % of TXs' Number covered by Major Wallets", xlab = "Top 50 Wallets", ylab = "Percentage of all Transactions Number")

# top100_wallet_volume <- head(m_w[order(-vol_tx),c("wallet","vol_tx")], 100)
# top100_wallet_volume$cum <- cumsum(top100_wallet_volume$vol_tx)
# top100_wallet_volume$perc <- top100_wallet_volume$cum/tx_volume*100/2
# plot(top100_wallet_volume$perc, main = "Cumulative % of TXs' Volume covered by Major Receivers", xlab = "Top 100 Receivers", ylab = "Percentage of all Transactions Volume")

hist(m_w$balance, col = "orange", border = "grey", xlim = range(-1e+24,1e+24), main = "Distribution of Balances within Studied Period", xlab = "Net Balances of Wallets")



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
