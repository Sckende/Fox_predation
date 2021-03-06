rm(list = ls())
setwd(dir = "C:/Users/HP_9470m/OneDrive - Université de Moncton/Doc doc doc/Ph.D. - ANALYSES/R analysis/Data")
list.files()
data <- read.table("FOX_PAPER_Complete_database.txt", h = T, sep = "\t", dec = ".") # ***Climatic variables per 4hours observation***
summary(data)

# ****** #
#data <- data[!data$YEAR %in% 2004:2005,]

library("viridis") # For colors in plot
library("lme4") # For generalised linear models
library("glmmTMB")
library("optimx")
library("visreg") # Vizualisation of model effects
library("DHARMa") # For simulations
library("AICcmodavg") # For AIC comparison
library("car") # For the Anova command
library("multcomp") # For the contrast analysis
library("emmeans") # For the contrast analysis
library("modEvA") # For the variance explained
library("scales") # For the colour transparency
library("ggplot2")
library("GGally") # correlation panels
library("MuMIn")

# -------------------------------- #
#### Correlation btw variables ####
# ------------------------------ #

panel.cor <- function(x, y, digits = 2, cex.cor, ...)
{
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  # correlation coefficient
  r <- cor(x, y)
  txt <- format(c(r, 0.123456789), digits = digits)[1]
  txt <- paste("r = ", txt, sep = "")
  text(0.5, 0.6, txt)
  
  # p-value calculation
  p <- cor.test(x, y)$p.value
  txt2 <- format(c(p, 0.123456789), digits = digits)[1]
  txt2 <- paste("p = ", txt2, sep = "")
  if(p<0.01) txt2 <- paste("p = ", "< 0.01", sep = "")
  text(0.5, 0.4, txt2)
}
x11(); 
pairs(data[, c(2, 14, 17, 21, 22, 24)], upper.panel = panel.cor)

ggpairs(data[, c(2, 14, 17, 21, 22, 24)])
graphics.off()

# ------------------------------- #
#### Creation of the database ####
# ------------------------------#

# Keeping the observation more or equal than 3 min (180 s)
data <- data[data$OBS.LENGTH >= 180,]

# Creation of the random variable fox.year
data$fox.year <- paste(data$FOX.ID, data$YEAR, sep = "-")
data$fox.year <- as.factor(data$fox.year)

# Creation of a lemming variable with only two levels
data$lmg.crash[data$lmg.year == "crash"] <- "crash"
data$lmg.crash[data$lmg.year %in% c("inter", "peak")] <- "noCrash"

# Creation of the variable for the offset
data$log.obs <- log(data$OBS.LENGTH)

# Log transformation of lemming abundance variable
data$log.lmgAbun <- log(data$lmg.abun)

# WARNING - data_test contains a modified variable for "lmg.year"
data_test <- data
data_test$lmg.year <- as.character(data_test$lmg.year)
data_test$lmg.year[data_test$lmg.abun < 1] <- "crash"

data_test$lmg.crash[data_test$lmg.year == "crash"] <- "crash"

data_test$lmg.year <- as.factor(data_test$lmg.year)
data_test$lmg.crash <- as.factor(data_test$lmg.crash)

summary(data_test)

# Scaled data
scaleData <- apply(data_test[,c(2, 14, 17, 21, 22, 24, 28)], MARGIN = 2, scale)

scaleData <- cbind(scaleData, data_test[, c(7, 8, 23, 25:27)])
summary(scaleData)
# ----------------------------- #
#### Poisson family in GLM-M ####
# ------------------------------#

# ---------------------------- #
# Choice between lmg variables#
# -------------------------- #

control <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2000000)) # Helping the convergence with "maxfun" increasing the number of iterations 

lmgMod <- list()

lmgMod[[1]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens + DATE*lmg.crash
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
lmgMod[[2]] <- glmer(AD.atq.number ~ prec*lmg.year + max.temp*lmg.year + nest.dens + DATE*lmg.year
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
lmgMod[[3]] <- glmer(AD.atq.number ~ prec*lmg.abun + max.temp*lmg.abun + nest.dens + DATE*lmg.abun
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
lmgMod[[4]] <- glmer(AD.atq.number ~ prec + max.temp + nest.dens + DATE + lmg.crash
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
lmgMod[[5]] <- glmer(AD.atq.number ~ prec + max.temp + nest.dens + DATE + lmg.year
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
lmgMod[[6]] <- glmer(AD.atq.number ~ prec + max.temp + nest.dens + DATE + lmg.abun
                     + (1|fox.year)
                     + offset(log.obs),
                     family = poisson(),
                     control = control,
                     #method = "REML",
                     #select = TRUE,
                     data = scaleData)
aictab(lmgMod)

# The best variable to use for lemming abundance is "lmg.crash"

# ------------------- #
# Models compairison #
# ----------------- #

control <- glmerControl(optimizer = "bobyqa", optCtrl = list(maxfun = 2000000)) # Helping the convergence with "maxfun" increasing the number of iterations 

# Models
mod <- list()
mod[[1]] <- glmer(AD.atq.number ~ prec + I(max.temp^2) + max.wind + nest.dens + lmg.crash
               + (1|fox.year)
               + offset(log.obs),
               family = poisson(),
               #method = "REML",
               #select = TRUE,
               data = scaleData)
summary(mod[[1]])

mod[[2]] <- glmer(AD.atq.number ~ prec + max.temp + I(max.temp^2) + max.wind + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[2]])

mod[[3]] <- glmer(AD.atq.number ~ prec + max.temp + max.wind + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[3]])

mod[[4]] <- glmer(AD.atq.number ~ prec + max.temp + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[4]])

mod[[5]] <- glmer(AD.atq.number ~ prec + max.temp
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[5]])

mod[[6]] <- glmer(AD.atq.number ~ prec + max.temp + max.wind
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[6]])

mod[[7]] <- glmer(AD.atq.number ~ 1
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[7]])

mod[[8]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + max.wind*lmg.crash + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  control = control,
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[8]])

mod[[9]] <- glmer(AD.atq.number ~  max.temp*lmg.crash + max.wind*lmg.crash + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[9]])

mod[[10]] <- glmer(AD.atq.number ~  max.temp*lmg.crash  + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[10]])

mod[[11]] <- glmer(AD.atq.number ~ prec + I(max.temp^2) + max.wind + nest.dens + lmg.year
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[11]])

mod[[12]] <- glmer(AD.atq.number ~ max.temp + prec + max.wind + nest.dens + lmg.year
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[12]])

mod[[13]] <- glmer(AD.atq.number ~ max.temp + nest.dens + lmg.year
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[13]])

mod[[14]] <- glmer(AD.atq.number ~ nest.dens + lmg.year
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[14]])

mod[[15]] <- glmer(AD.atq.number ~ prec*lmg.year + max.temp*lmg.year + max.wind*lmg.year + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  control = control,
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[15]])
visreg(mod[[15]], "max.temp", by = "lmg.year")
visreg(mod[[15]], "prec", by = "lmg.year")
visreg(mod[[15]], "max.wind", by = "lmg.year")

mod[[16]] <- glmer(AD.atq.number ~ prec*lmg.year + max.temp*lmg.year  + nest.dens
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[16]])

mod[[17]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens
                  + (1|fox.year)
                  + offset(log.obs),
                  family = poisson(),
                  control = control,
                  #method = "REML",
                  #select = TRUE,
                  data = scaleData)
summary(mod[[17]])
visreg(mod[[17]], "max.temp", by = "lmg.crash")
visreg(mod[[17]], "prec", by = "lmg.crash")

# Tests with DHARma package
sims <- simulateResiduals(mod[[17]])
plot(sims)
testDispersion(sims)
testZeroInflation(sims)
# Check for the distribution of predictions vs. raw data
par(mfrow = c(1, 2))
hist(data$AD.atq.number, breaks = 0:50)
hist(predict(mod[[17]], type = "response"), breaks = 0:50)


mod[[18]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens + ns(DATE, 5)*lmg.crash
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[18]])
visreg(mod[[18]], "max.temp", by = "lmg.crash", scale = "response", overlay = TRUE, bty = "n")
visreg(mod[[18]], "prec", by = "lmg.crash", scale = "response", overlay = TRUE, bty = "n")
visreg(mod[[18]], "DATE", by = "lmg.crash", scale = "response", overlay = TRUE, bty = "n")
visreg(mod[[18]], "nest.dens", by = "lmg.crash", scale = "response", overlay = TRUE, bty = "n")

mod[[19]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens*lmg.crash + DATE
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[19]])

mod[[20]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens + DATE*lmg.crash
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[20]])
x11(); par(mfrow = c(2, 2))
visreg(mod[[20]], "max.temp", by = "lmg.crash", overlay = T)
visreg(mod[[20]], "prec", by = "lmg.crash", overlay = T)
visreg(mod[[20]], "DATE", by = "lmg.crash", overlay = T)
visreg(mod[[20]], "nest.dens")

mod[[21]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens*lmg.crash + DATE*lmg.crash
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[21]])
X11(); par(mfrow = c(2, 2))
visreg(mod[[21]], "max.temp", by = "lmg.crash", overlay = T)
visreg(mod[[21]], "prec", by = "lmg.crash", overlay = T)
visreg(mod[[21]], "DATE", by = "lmg.crash", overlay = T)
visreg(mod[[21]], "nest.dens", by = "lmg.crash", overlay = T)

#####################################
mod[[22]] <- glmer(AD.atq.number ~ prec*lmg.abun + max.temp*lmg.abun + nest.dens*lmg.abun + DATE
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[22]])

mod[[23]] <- glmer(AD.atq.number ~ prec*lmg.abun + max.temp*lmg.abun + nest.dens + DATE*lmg.abun
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[23]])

mod[[24]] <- glmer(AD.atq.number ~ prec*lmg.abun + max.temp*lmg.abun + nest.dens*lmg.abun + DATE*lmg.abun
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[24]])


mod[[25]] <- glmer(AD.atq.number ~ prec*lmg.abun + max.temp*lmg.abun + nest.dens + DATE
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   control = control,
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)
summary(mod[[25]])

mod[[26]] <- glmer(AD.atq.number ~ prec*lmg.crash + max.temp*lmg.crash + nest.dens + DATE + DATE
                   + (1|fox.year)
                   + offset(log.obs),
                   family = poisson(),
                   #method = "REML",
                   #select = TRUE,
                   data = scaleData)

# AIC table
aictab(mod, modnames = NULL)

# Computation of R squared
r.squaredGLMM(mod[[20]])
r.squaredGLMM(mod[[20]], mod[[7]]) # Check the method !

# Save the best model for rmarkdown document
 # save(mod, file = "FOX_attack_all_glmm.rda")
 # bestMod <- mod[[18]]
 # save(bestMod, file = "FOX_attack_best_glmm.rda")

# ------------------- #
#### Results plot ####
# ------------------#

# Atq number vs. max.temp #
# ---------------------- #
range(data_test$max.temp) # 0.595 - 15.351

v <- seq(0, 16, by = 0.01)
newdat.crash <- data.frame(max.temp = v,
                     prec = mean(data_test$prec),
                     nest.dens = mean(data_test$nest.dens),
                     DATE = mean(data_test$DATE),
                     lmg.crash = "crash",
                     log.obs = mean(data$log.obs))
newdat.noCrash <- data.frame(max.temp = v,
                           prec = mean(data_test$prec),
                           nest.dens = mean(data_test$nest.dens),
                           DATE = mean(data_test$DATE),
                           lmg.crash = "noCrash",
                           log.obs = mean(data$log.obs))

p.crash <- predict(mod[[18]], newdata = newdat.crash, type = "response", re.form = NA)
p.noCrash <- predict(mod[[18]], newdata = newdat.noCrash, type = "response", re.form = NA)

#plot(data$max.temp, data$AD.atq.rate)

# Atq number vs. prec #
# ---------------------- #
range(data_test$prec) # 0 - 20

v1 <- seq(0, 20, by = 0.01)
newdat1.crash <- data.frame(max.temp = mean(data_test$max.temp),
                            prec = v1,
                            nest.dens = mean(data_test$nest.dens),
                            lmg.crash = "crash",
                            DATE = mean(data_test$DATE),
                            log.obs = mean(data_test$log.obs))

p1.crash <- predict(mod[[18]], newdata = newdat1.crash, type = "response", re.form = NA)

# ----- #
newdat1.noCrash <- data.frame(max.temp = mean(data_test$max.temp),
                            prec = v1,
                            nest.dens = mean(data_test$nest.dens),
                            lmg.crash = "noCrash",
                            DATE = mean(data_test$DATE),
                            log.obs = mean(data_test$log.obs))

p1.noCrash <- predict(mod[[18]], newdata = newdat1.noCrash, type = "response", re.form = NA)

#plot(data$max.temp, data$AD.atq.rate)
#plot(v1, p1, type = "l", bty = "n", lwd = 2, xlab = "Cumulative precipitation")

# Atq number vs. nest.dens #
# ----------------------- #
range(data_test$nest.dens) # 0.42 - 9.26

v2 <- seq(0, 10, by = 0.01)
newdat2 <- data.frame(max.temp = mean(data_test$max.temp),
                            prec = mean(data_test$prec),
                            nest.dens = v2,
                            DATE = mean(data_test$DATE),
                            lmg.crash = "noCrash",
                            log.obs = mean(data$log.obs))

p2 <- predict(mod[[18]], newdata = newdat2, type = "response", re.form = NA)

# Atq number vs. date #
# ------------------- #
range(data_test$DATE) # 159 - 205

v3 <- seq(159, 205, by = 1)
newdat3 <- data.frame(max.temp = mean(data_test$max.temp),
                      prec = mean(data_test$prec),
                      nest.dens = mean(data_test$nest.dens),
                      DATE = v3,
                      lmg.crash = "noCrash",
                      log.obs = mean(data$log.obs))

p3 <- predict(mod[[18]], newdata = newdat3, type = "response", re.form = NA)

# --------- #
# GRAPHICS #
# ------- #

# -------------------- #
# Temperature effect...
# ------------------- #
x11()
par(mfrow = c(1, 2))
# ------ #
plot(v, p.crash, ylim = c(0, 7), type = "l", bty = "n", lwd = 2.5, xlab = "Maximal temperature", ylab = "Fox attack number per hour", col = "darkorange4", main = "Crash of lemmings")
# ... & associated random effects 
re <- unique(data_test$fox.year)
for(i in re){
  nd2.crash <- data.frame(max.temp = v,
                              prec = mean(data_test$prec),
                              nest.dens = mean(data_test$nest.dens),
                              DATE = mean(data_test$DATE),
                              lmg.crash = "crash",
                        log.obs = mean(data_test$log.obs),
                        fox.year = i)
  pp.crash <- predict(mod[[18]], newdata = nd2.crash, type = "response")
  lines(v, pp.crash, type = "l", lwd = 1, col = alpha("darkorange", 0.25))
}
points(data_test$max.temp, 3600*data_test$AD.atq.rate,col = "darkorange4") # WARNINGS ! points are missing on the plot because their value is really high

# ------ #
plot(v, p.noCrash, ylim = c(0, 7), type = "l", bty = "n", lwd = 2.5, xlab = "Maximal temperature", ylab = "Fox attack number per hour", col = "darkorange4", main = "No crash of lemming")
# ... & associated random effects 
re <- unique(data_test$fox.year)
for(i in re){
  nd2.noCrash <- data.frame(max.temp = v,
                              prec = mean(data_test$prec),
                              nest.dens = mean(data_test$nest.dens),
                              DATE = mean(data_test$DATE),
                              lmg.crash = "noCrash",
                              log.obs = mean(data_test$log.obs),
                              fox.year = i)
  pp.noCrash <- predict(mod[[18]], newdata = nd2.noCrash, type = "response")
  lines(v, pp.noCrash, type = "l", lwd = 1, col = alpha("darkorange", 0.25))
}
points(data_test$max.temp, 3600*data_test$AD.atq.rate,col = "darkorange4") # WARNINGS ! points are missing on the plot because their value is really high

# ------------------------ #
# Precipitation effects....#
# ------------------------ #
x11()
par(mfrow = c(1, 2))
# ----- #
plot(v1, p1.crash, type = "l", ylim = c(0, 4), lwd = 2, col = "skyblue4", bty = "n", ylab = "Fox attack number per hour", xlab = "Cumulative precipitation (mm)", main = "Crash of lemmings")

# ... & associated random effects
re <- unique(data_test$fox.year)
for(i in re){
  nd3.crash <- data.frame(max.temp = mean(data_test$max.temp),
                              prec = v1,
                              nest.dens = mean(data_test$nest.dens),
                              DATE = mean(data_test$DATE),
                              lmg.crash = "crash",
                              log.obs = mean(data_test$log.obs),
                              fox.year = i)
  pp.crash <- predict(mod[[18]], newdata = nd3.crash, type = "response")
  lines(v1, pp.crash, type = "l", lwd = 1, col = alpha("skyblue3", 0.25))
}
points(data_test$prec, 3600*data_test$AD.atq.rate, col = "skyblue4") # WARNINGS ! points are missing on the plot because their value is really high

# ----- #
plot(v1, p1.noCrash, type = "l", ylim = c(0, 4), lwd = 2, col = "skyblue4", bty = "n", ylab = "Fox attack number per hour", xlab = "Cumulative precipitation (mm)", main = "No crash of lemmings")

# ... & associated random effects
re <- unique(data_test$fox.year)
for(i in re){
  nd3.noCrash <- data.frame(max.temp = mean(data_test$max.temp),
                              prec = v1,
                              nest.dens = mean(data_test$nest.dens),
                              DATE = mean(data_test$DATE),
                              lmg.crash = "noCrash",
                              log.obs = mean(data_test$log.obs),
                              fox.year = i)
  pp.noCrash <- predict(mod[[18]], newdata = nd3.noCrash, type = "response")
  lines(v1, pp.noCrash, type = "l", lwd = 1, col = alpha("skyblue3", 0.25))
}
points(data_test$prec, 3600*data_test$AD.atq.rate, col = "skyblue4") # WARNINGS ! points are missing on the plot because their value is really high

# ----------------------- #
# Nest density effect ...#
# --------------------- #
x11()
par(mfrow = c(1, 2))
plot(v2, p2, ylim = c(0, 6), type = "l", lwd = 2, bty = "n", xlab = "Goose nest density", col = "darkgreen", ylab = "Fox attack number per hour")

# ... & associated random effects
re <- unique(data_test$fox.year)
for(i in re){
  nd4 <- data.frame(max.temp = mean(data_test$max.temp),
                    prec = mean(data_test$prec),
                    nest.dens = v2,
                    DATE = mean(data_test$DATE),
                    lmg.crash = "noCrash", 
                    log.obs = mean(data$log.obs),
                    fox.year = i)
  pp <- predict(mod[[18]], newdata = nd4, type = "response")
  lines(v2, pp, type = "l", lwd = 1, col = alpha("green", 0.25))
}
points(data_test$nest.dens, 3600*data_test$AD.atq.rate, col = "darkgreen") # WARNINGS ! points are missing on the plot because their value is really high

# --------------- #
# Date effect ...#
# ------------- #
plot(v3, p3, ylim = c(0, 6), type = "l", lwd = 2, bty = "n", xlab = "Date of observations", col = "plum4", ylab = "Fox attack number per hour")

# ... & associated random effects
re <- unique(data_test$fox.year)
for(i in re){
  nd5 <- data.frame(max.temp = mean(data_test$max.temp),
                    prec = mean(data_test$prec),
                    nest.dens = mean(data_test$nest.dens),
                    DATE = v3,
                    lmg.crash = "noCrash", 
                    log.obs = mean(data$log.obs),
                    fox.year = i)
  pp <- predict(mod[[18]], newdata = nd5, type = "response")
  lines(v3, pp, type = "l", lwd = 1, col = alpha("plum3", 0.25))
}
points(data_test$DATE, 3600*data_test$AD.atq.rate, col = "plum4") # WARNINGS ! points are missing on the plot because their value is really high

graphics.off()
