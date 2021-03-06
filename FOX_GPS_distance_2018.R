getwd()
setwd("C:/Users/HP_9470m/OneDrive - Université de Moncton/Doc doc doc/Ph.D. - ANALYSES/R analysis/Data")
list.files()
mvt <- read.table("FOX_daily_distances_0701_to_0716.txt", h = T, sep = ";")
prec <- read.table("PREC_Bylot_2018.txt", h = T, sep = "\t", dec = ",")
temp <- read.table("TEMP-PondInlet-JUIL_2018_CLEAN.csv", h = T, sep = ",", dec = ".")
temp <- na.omit(temp)

summary(mvt)
mvt$date <- strptime(mvt$date, format = "%Y-%m-%d")
mvt$JJ <- mvt$date$yday + 1
mvt$Device.ID <- as.factor(mvt$Device.ID) 
hist(mvt$dist_km, breaks = 19:77)

summary(prec)
hist(prec$Pluie, breaks = min(prec$Pluie):max(prec$Pluie))
prec <- prec[prec$Mois == "juillet",]
prec <- droplevels(prec)
summary(temp)

hist(temp$Rel_Hum, breaks = min(temp$Rel_Hum):max(temp$Rel_Hum))
h <- hist(temp$Temp)
hist(temp$Wind_speed)
utils::str(hist(temp$Temp, breaks = -2:18))
temp$date <- paste(temp$Year, temp$Month, temp$Day, sep = "-")
temp$date <- strptime(temp$date, format = "%Y-%m-%d")
temp$JJ <- temp$date$yday + 1


# Creation of the new database

fox <- mvt
fox$rain <- prec$Pluie[match(fox$JJ, prec$Date)]
fox$temp <- temp$Temp[match(fox$JJ, temp$JJ)]
fox$wind <- temp$Wind_speed[match(fox$JJ, temp$JJ)]
fox$humid <- temp$Rel_Hum[match(fox$JJ, temp$JJ)]

summary(fox)                       

# Graphical explorations
  # Boxplot
cols <- ifelse(fox$sex == "F", "pink", "black")
boxplot(fox$dist_km~fox$Device.ID, col = cols)

require(lattice)
xyplot(mvt$dist_km ~ mvt$JJ|mvt$sex, group = mvt$Device.ID, type = "l")

x11()

par(mfrow = c(2, 2), bty = "n")

plot(prec$Date, prec$Pluie, type = "l", xlab = "JJ", ylab = "prec", col = "blue")
plot(unique(temp$JJ), tapply(temp$Temp, temp$JJ, mean), type = "l", xlab = "JJ", ylab = "temp", col = "darkorange")
plot(unique(temp$JJ), tapply(temp$Rel_Hum, temp$JJ, mean), type = "l", xlab = "JJ", ylab = "Rel_Hum", col = "darkblue")
plot(unique(temp$JJ), tapply(temp$Wind_speed, temp$JJ, mean), type = "l", xlab = "JJ", ylab = "wind_speed", col = "darkgrey")
par(new = TRUE)
plot(mvt$JJ[mvt$Device.ID == "926007"], mvt$dist_km[mvt$Device.ID == "926007"], type = "l", yaxt = "n")
axis(3)

# Models

require(nlme)
fox0 <- lme(fox$dist_km ~ fox$sex, random = 1|fox$Device.ID)
anova(fox0)
summary(fox0)



fox1 <- lme(fox$dist_km ~ fox$sex + fox$rain + fox$temp, random = 1|fox$Device.ID)

summary(fox1)
anova(fox1)
anova(fox0, fox1)
