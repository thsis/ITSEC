if(!require("data.table")) install.packages("data.table")
if(!require("dplyr")) install.packages("dplyr")
if(!require("ggplot2")) install.packages("ggplot2")
if(!require("lubridate")) install.packages("lubridate")
if(!require("maptools")) install.packages("maptools")
if(!require("scales")) install.packages("scales")

library("data.table")
library("dplyr")
library("ggplot2")
library("lubridate")
library("maptools")
library("scales")
library(xtable)

# Data transformations
e_w_rate <- 1000000000000000000 #1 Ether equals x wei
s_w_rate <- 1000000000000 #1 Szabo equals x wei

dt <- read.csv("ethereum-data-large.csv", colClasses = "character")
s1 <- summary(dt)

colnames_1 <- c("block_hash", "tx_hash", "sender", "receiver")
colnames_2 <- c("block_gas", "gas_limit", "inception_time",
                "value", "gas_used", "gas_price")
dt[colnames_1] <- lapply(dt[colnames_1], as.factor)
dt[colnames_2] <- lapply(dt[colnames_2], as.numeric)

dt$inception_time <- as.POSIXct(dt$inception_time, origin="1970-01-01")
dt$time <- trunc(dt$inception_time, units = "hours")
dt$time <- as.POSIXct(dt$time, origin="1970-01-01")
dt$day <- trunc(dt$inception_time, units = "days")
dt$day <- as.POSIXct(dt$day, origin="1970-01-01")
s2 <- summary(dt)

dt <- dt[!is.na(dt$value),]

dt$fee <- dt$gas_used*dt$gas_price

dt_sum <- lapply(dt[,c("value","gas_used","gas_price", "fee")],sum)
dt_median <- lapply(dt[,c("value","gas_used","gas_price", "fee")],median)
dt_max <- lapply(dt[,c("value","gas_used","gas_price", "fee")],max)

#----Data description----
s3 <- summary(dt)

# Graphs

hist(dt$gas_used, col = "orange", border = "grey",
     main = "Distribution of Gas used per Transaction",
     xlab = "Amount of Gas per Transaction, in wei",
     ylab = "Number of Transactions", ylim = c(0,70000))
boxplot(dt$gas_used,
        # main = "Boxplot of Gas used per Transaction",
        xlab = "Amount of Gas per Transaction, in wei")

# hist(dt$gas_price)
# boxplot(dt$gas_price)

hist(dt$fee/e_w_rate, col = "orange", border = "grey",
     # main = "Distribution of Fees paid per Transaction",
     xlab = "Fee per Transaction, in ether",
     ylab = "Number of Transactions",
     ylim = c(0,700),
     xlim = c(0,2),
     breaks = 25000)
boxplot(dt$fee/e_w_rate,
        xlab = "Fee per Transaction, in ether")

# CAREFULL!! THIS TAKES TX to make a calculation
hist(dt$value/e_w_rate, col = "orange", border = "grey",
     xlab = "Value of a Transaction, in ether",
     ylab = "Number of Transactions",
     ylim = c(0,50),
     breaks = 50)
boxplot(dt$value/e_w_rate,
        xlab = "Value of a Transaction, in ether")

# Add fee calculation
tx_n <- nrow(dt)
tx_volume <- sum(dt$value, na.rm = TRUE)
tx_average_value <- tx_n/tx_volume
tx_n; tx_volume; tx_average_value

block_descriptives <- dt %>%
  group_by(block_hash) %>%
  summarize(block_tx=n(),
            block_tx_perc=n()/tx_n*100,
            block_volume=sum(value),
            block_volume_perc=sum(value)/tx_volume*100,
            block_average_tx_value=mean(value)) %>%
  arrange(desc(block_tx))
summary(block_descriptives)

dt_sum$block_tx <- sum(block_descriptives$block_tx)
dt_sum$block_volume <- sum(block_descriptives$block_volume)

dt_median$block_tx <- median(block_descriptives$block_tx)
dt_median$block_volume <- median(block_descriptives$block_volume)

dt_max$block_tx <- max(block_descriptives$block_tx)
dt_max$block_volume <- max(block_descriptives$block_volume)

hist(block_descriptives$block_tx, col = "orange", border = "grey",
     xlab = "Number of Transactions",
     ylab = "Number of Blocks",
     ylim = c(0,7000))
hist(block_descriptives$block_volume/e_w_rate,
     col = "orange", border = "grey",
     xlab = "Volume of Transactions, in ether",
     ylab = "Number of Blocks", ylim = c(0,100), breaks = 100)

time_descriptives <- dt %>%
  group_by(day) %>%
  summarize(tx_number=n(),
            tx_perc=n()/tx_n*100,
            tx_vol=sum(value, na.rm = TRUE),
            tx_vol_perc=sum(value, na.rm = TRUE)/tx_volume*100,
            tx_average_value=mean(value, na.rm = TRUE)) %>%
  arrange(desc(day))

# remove first and last day which are not complete
time_descriptives <- time_descriptives[-c(1, nrow(time_descriptives)), ]
summary(time_descriptives)


dt_sum$tx_number <- sum(time_descriptives$tx_number)
dt_sum$tx_volume <- sum(time_descriptives$tx_vol)

dt_median$tx_number <- median(time_descriptives$tx_number)
dt_median$tx_volume <- median(time_descriptives$tx_vol)

dt_max$tx_number <- max(time_descriptives$tx_number)
dt_max$tx_volume <- max(time_descriptives$tx_vol)

ggplot(data=time_descriptives,aes(x=day, y=tx_number)) +
  geom_line(colour="blue") +
  ylab("Number of Transactions") +
  xlab("Date")

ggplot(data=time_descriptives,aes(x=day, y=tx_vol/e_w_rate)) +
  geom_line(colour="blue") +
  # ggtitle("Volume of Transactions over Time, in ether") +
  ylab("Volume of Transactions") +
  xlab("Date")


# Major wallets
major_senders <- dt %>%
  group_by(sender) %>%
  summarize(sender_tx=n(),
            sender_tx_perc=n()/tx_n*100,
            sender_volume=-sum(value),
            sender_volume_perc=-sum(value)/tx_volume*100,
            sender_average_value=-mean(value)) %>%
  arrange(desc(sender_tx))
colnames(major_senders)[1] <- "wallet"
summary(major_senders)

major_receivers <- dt %>%
  group_by(receiver) %>%
  summarize(receiver_tx=n(),
            receiver_tx_perc=n()/tx_n*100,
            receiver_volume=sum(value),
            receiver_volume_perc=sum(value)/tx_volume*100,
            receiver_average_value=mean(value)) %>%
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
plot(top50_sender_tx$perc, ylim = c(0,100),
     xlab = "Top 50 Senders",
     ylab = "Percentage of all Transactions Number")

top50_receiver_tx <- head(m_w[order(-receiver_tx),c("wallet","receiver_tx")], 50)
top50_receiver_tx$cum <- cumsum(top50_receiver_tx$receiver_tx)
top50_receiver_tx$perc <- top50_receiver_tx$cum/tx_n*100
plot(top50_receiver_tx$perc, ylim = c(0,100),
     xlab = "Top 50 Receivers",
     ylab = "Percentage of all Transactions Number")


top50_sender_volume <- head(m_w[order(sender_volume),c("wallet","sender_volume")], 50)
top50_sender_volume$cum <- -cumsum(top50_sender_volume$sender_volume)
top50_sender_volume$perc <- top50_sender_volume$cum/tx_volume*100
plot(top50_sender_volume$perc, ylim = c(0,100),
     xlab = "Top 50 Senders",
     ylab = "Percentage of all Transactions Volume")

top50_receiver_volume <- head(m_w[order(-receiver_volume),c("wallet","receiver_volume")], 50)
top50_receiver_volume$cum <- cumsum(top50_receiver_volume$receiver_volume)
top50_receiver_volume$perc <- top50_receiver_volume$cum/tx_volume*100
plot(top50_receiver_volume$perc, ylim = c(0,100),
     xlab = "Top 50 Receivers",
     ylab = "Percentage of all Transactions Volume")

plot(top50_sender_tx$perc, ylim = c(0,100), col = "blue",
     xlab = "Top 50 Senders (blue) and Top 50 Receivers (orange)",
     ylab = "Percentage of covered Transactions")
points(top50_receiver_tx$perc, ylim = c(0,100), col = "orange")

plot(top50_sender_volume$perc, ylim = c(0,100), col = "blue",
     # main = "Cumulative % of Volume covered by Major Users",
     xlab = "Top 50 Senders (blue) and Top 50 Receivers (orange)",
     ylab = "Percentage of covered Volume")
points(top50_receiver_volume$perc, ylim = c(0,100), col = "orange")

plot(top50_sender_tx$perc,
     ylim = c(0,100),
     col = "blue",
     ylab = "Cumulative Percentage")
points(top50_sender_volume$perc, ylim = c(0,100), col = "orange")

plot(top50_receiver_tx$perc, ylim = c(0,100), col = "blue",
     ylab = "Cumulative Percentage")
points(top50_receiver_volume$perc, ylim = c(0,100), col = "orange")


intersect_volume <- intersect(top50_receiver_volume$wallet,
                              top50_sender_volume$wallet)
intersect_tx <- intersect(top50_receiver_tx$wallet,
                          top50_sender_tx$wallet)

intersect_senders <- intersect(top50_sender_tx$wallet,
                               top50_sender_volume$wallet)
intersect_receivers <- intersect(top50_receiver_tx$wallet,
                                 top50_receiver_volume$wallet)

top50_wallet_tx <- head(m_w[order(-number_tx),c("wallet","number_tx")], 50)
top50_wallet_tx$cum <- cumsum(top50_wallet_tx$number_tx)
top50_wallet_tx$perc <- top50_wallet_tx$cum/tx_n*100/2
plot(top50_wallet_tx$perc, ylim = c(0,100),
     xlab = "Top 50 Wallets",
     ylab = "Percentage of all Transactions Number")

hist(m_w$balance/e_w_rate,
     col = "orange",
     border = "grey",
     ylim = range(0,10),
     xlab = "Net Balances of Wallets, in ether",
     ylab = "Number of Wallets",breaks = 50)
