setwd('~/Work/GovHack2015/ParcMe')
data = read.csv('Parking_Events_Cutdown.csv')
#------1p event duration density------
clean = data[data$DurationSeconds > 0 & data$SignPlateId == 6 & data$DurationSeconds<10800, ]
binned <- as.data.frame(cut(clean$DurationSeconds, seq(from = 0, to = 10800, by = 60), labels = 1:180))
binned$Duration <- clean$DurationSeconds
names(binned)[names(binned)=="cut(clean$DurationSeconds, seq(from = 0, to = 10800, by = 60), labels = 1:180)"] <- "two"
par(mar = c(5,5,2,5))
plot(binned$two, col='blue', axes = F, main = "Event Duration Density - 1P limit", xlab = "duration (seconds)", ylab = "no. of events")
axis(side=1, at=seq(from = 1800, to = 10800, by = 60))
axis(side=2, at=seq(from = 0, to = 2000, by = 100))
par(new = T)
density <- clean$DurationSeconds / 60
d <- density(density, bw = 0.5, from = 1, to = 180) # returns the density data 
plot(d$x, d$y, col = "red", type = 'l', axes = F, xlab = NA, ylab = NA)
mtext(side = 4, line = 3, "density")
axis(side = 4)
#-------------------------------------
#------2p event duration density------
clean = data[data$DurationSeconds > 0 & data$SignPlateId == 8 & data$DurationSeconds<14400, ]
binned <- as.data.frame(cut(clean$DurationSeconds, seq(from = 0, to = 14400, by = 60), labels = 1:240))
binned$Duration <- clean$DurationSeconds
names(binned)[names(binned)=="cut(clean$DurationSeconds, seq(from = 0, to = 14400, by = 60), labels = 1:240)"] <- "two"
par(mar = c(5,5,2,5))
plot(binned$two, col='blue', axes = F, main = "Event Duration Density - 2P limit", xlab = "duration (seconds)", ylab = "no. of events")
axis(side=1, at=seq(from = 0, to = 14400, by = 60))
axis(side=2, at=seq(from = 0, to = 2000, by = 100))
par(new = T)
density <- clean$DurationSeconds / 60
d <- density(density, bw = 0.5, from = 1, to = 240) # returns the density data 
plot(d$x, d$y, col = "red", type = 'l', axes = F, xlab = NA, ylab = NA)
mtext(side = 4, line = 3, "density")
axis(side = 4)
#-------------------------------------
