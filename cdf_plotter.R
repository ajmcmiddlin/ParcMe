setwd('~/Work/GovHack2015/ParcMe')
density = read.csv('density_data.csv')
plot(density, col='blue', main="CDF for duration",
     xlab="duration (time since arrival) (seconds)", ylab="probability",
     xlim=c(0, 10800), ylim=c(0, 1), type = 'l')

hazard = read.csv('hazard_data.csv')
plot(hazard$mins, hazard$hazard, col='blue', main="Hazard function",
     xlab="duration (time since arrival) (seconds)", ylab="hazard",
     xlim=c(0, 10800), ylim=c(0, 0.1), type = 'l')
