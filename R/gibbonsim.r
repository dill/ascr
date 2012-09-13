library("secr")
library("CircStats")
library("inline")
library("Rcpp")
library("R2adb")

if (.Platform$OS == "unix"){
    source("/home/ben/SECR/R/helpers.r")
    source("/home/ben/SECR/R/admbsecr.r")
    load("/home/ben/SECR/Data/Gibbons/gibbons_data.RData")
    admb.dir <- "/home/ben/SECR/ADMB"
    dat.dir <- "/home/ben/SECR/Data/Gibbons/gibbons.txt"
} else if (.Platform$OS == "windows"){
    source("C:\\Documents and Settings\\Ben\\My Documents\\SECR\\R\\helpers.r")
    source("C:\\Documents and Settings\\Ben\\My Documents\\SECR\\R\\admbsecr.r")
    load("C:\\Documents and Settings\\Ben\\My Documents\\SECR\\Data\\Gibbons\\gibbons_data.RData")
    admb.dir <- "C:\\Documents and Settings\\Ben\\My Documents\\SECR\\ADMB"
    dat.dir <- "C:\\Documents and Settings\\Ben\\My Documents\\SECR\\Data\\Gibbons\\gibbons.txt"
}

nsims <- 1
buffer <- 6000
mask.spacing <- 100
trap.spacing <- 2500


## True parameter values:
D <- 0.0416
g0 <- 0.99999
sigma <- 1250
kappa <- 140
truepars <- c(D = D, g0 = g0, sigma = sigma, kappa = kappa)
detectpars <- list(g0 = g0, sigma = sigma)

## Setting up mask and traps
traps <- make.grid(nx = 3, ny = 1, spacing = trap.spacing, detector = "proximity")
ntraps <- nrow(traps)
mask <- make.mask(traps, spacing = mask.spacing, type = "trapbuffer", buffer = buffer)
nmask <- nrow(mask)
A <- attr(mask, "area")
mask.dists <- distances.cpp(as.matrix(traps), as.matrix(mask))
mask.angs <- angles.cpp(as.matrix(traps), as.matrix(mask))

simprobs <- NULL
angprobs <- NULL
simpleres <- matrix(0, nrow = nsims, ncol = 3)
angres <- matrix(0, nrow = nsims, ncol = 4)
asimpleres <- matrix(0, nrow = nsims, ncol = 3)
aangres <- matrix(0, nrow = nsims, ncol = 4)
colnames(simpleres) <- c("D", "g0", "sigma")
colnames(angres) <- c("D", "g0", "sigma", "kappa")
for (i in 1:nsims){
  if (i == 1){
    print(c("start", date()))
  } else if (i %% 100 == 0){
    print(c(i, date()))
  }
  ## Simulating data and setting things up for analysis
  popn <- sim.popn(D = D, core = traps, buffer = buffer)
  capthist <- sim.capthist(traps, popn, detectfn = 0, detectpar = detectpars, noccasions = 1,
                           renumber = FALSE)
  n <- nrow(capthist)
  ndets <- sum(capthist)
  cue.ids <- unique(as.numeric(rownames(capthist)))
  detections <- popn[cue.ids, ]
  radians <- t(angles.cpp(as.matrix(traps), as.matrix(detections)))
  radians <- array(radians, c(dim(radians), 1))
  errors <- array(rvm(ntraps*n, mean = 0, k = kappa), dim(radians))
  radians <- (radians + errors) %% (2*pi)
  radians[radians == 0] <- 2*pi
  radhist <- capthist
  radhist[radhist == 1] <- radians[radhist == 1]
  ## Straightforward SECR model using admbsecr()
  simplefit <- try(admbsecr(capt = capthist, traps = traps, mask = mask, sv = truepars[1:3],
                        admbwd = admb.dir, method = "simple", verbose = FALSE, autogen = FALSE),
                   silent = TRUE)
  if (class(simplefit) == "try-error"){
    simplefit <- try(admbsecr(capt = capthist, traps = traps, mask = mask, sv = "auto",
                              admbwd = admb.dir, method = "simple", verbose = FALSE,
                              autogen = FALSE), silent = TRUE)
  }
  if (class(simplefit) == "try-error"){
    simplecoef <- NA
    simprobs <- c(simprobs, i)
  } else {
    simplecoef <- coef(simplefit)
  }
  ## SECR model using supplementary angle data
  angfit <- try(admbsecr(capt = radhist, traps = traps, mask = mask, sv = truepars,
                     angs = mask.angs, admbwd = admb.dir, method = "ang", verbose = FALSE,
                     autogen = FALSE), silent = TRUE)
  if (class(angfit) == "try-error"){
    angfit <- try(admbsecr(capt = radhist, traps = traps, mask = mask, sv = "auto",
                       angs = mask.angs, admbwd = admb.dir, method = "ang", verbose = FALSE,
                       autogen = FALSE), silent = TRUE)
  }
  if (class(angfit) == "try-error"){
    angcoef <- NA
    angprobs <- c(angprobs, i)
  } else {
    angcoef <- coef(angfit)
  }
  simpleres[i, ] <- simplecoef
  angres[i, ] <- angcoef
  hash1 <- which(capthist[,1,]==1, arr.ind=T)-1
  hash0 <- which(capthist[,1,]==0, arr.ind=T)-1
  p <- c(log(D), logit(g0), log(sigma), log(kappa))
  sfit <- try(secr.fit(capthist, model = list(D ~ 1, g0 ~ 1, sigma ~ 1),
                       mask = mask, verify = FALSE, trace = FALSE), silent = TRUE)
  dfit <- try(nlm(f = secrlikelihood.cpp, p = p, method = 1, ncues = n,
                  ntraps = ntraps, npoints = nmask, radians = radhist[, 1, ],
                  hash1 = hash1, hash0 = hash0, mask_area = A,
                  mask_dists = mask.dists, mask_angs = mask.angs,
                  hessian = TRUE), silent = TRUE)
  if (class(sfit) == "try-error"){
    asimpleres[i, ] <- NA
  } else {
    ests <- sfit$fit$estimate
    asimpleres[i, ] <- c(exp(ests[1]), invlogit(ests[2]), exp(ests[3]))
  }
  if (class(dfit) == "try-error"){
    aangres[i, ] <- NA
  } else {
    ests <- dfit$estimate
    aangres[i, ] <- c(exp(ests[1]), invlogit(ests[2]), exp(ests[3:4]))
  }
  if (i == nsims){
    print(c("end", date()))
  }
}

simpleD <- simpleres[, 1]
angD <- angres[, 1]


probres <- angres[angres[, 4] > 699.9, ]

probs <- which(angres[, 2] < 0.99 | simpleres[, 2] < 0.99 | angres[, 4] > 300)
cutsim <- simpleres[-probs, ]
cutang <- angres[-probs, ]