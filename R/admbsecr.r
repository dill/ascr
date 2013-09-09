## Package imports for roxygenise to pass to NAMESPACE.
#' @import CircStats R2admb secr
#' @export stdEr
NULL

#' Fitting SECR models in ADMB
#'
#' Fits an SECR model, with our without supplementary information relevant to animal
#' location. Parameter estimation is done by maximum likelihood in ADMB.
#'
#' ADMB is called to fit an SECR model through use of the R2admb package. Different
#' methods are used depending on the additional information on animal location that is
#' collected. Different detection functions are used depending on the relationship between
#' detection probability and distance from detector.
#'
#' Note that the method \code{"ss"} is a special case in that it incorporates its own detection
#' function, and thus the half normal, hazard rate (etc) options cannot be specified. Instead,
#' either \code{"identity"} (the default) or \code{"log"} can be provided for the argument
#' \code{detfn}, which give the link function for the estimated received signal strengths.
#'
#' The parameter D, density of animals (in individuals per hectare) is always estimated.
#' The other parameters in the model depend on the method and the detection function used.
#'
#' Possible methods, along with their additional parameters, are as follows:
#'
#' \itemize{
#'    \item \code{"simple"}: Normal SECR with no additional information. No additional parameters.
#'     \item \code{"toa"}: SECR with precise time of arrival (TOA) recorded:
#'   \itemize{
#'          \item sigmatoa: Error term associated with the normal distribution used to model TOA.
#'   }
#'    \item \code{"ang"}: SECR with estimates of angle to animal recorded:
#'    \itemize{
#'          \item kappa:    Error term from a Von-Mises distribution, used to model estimated
#'                       angles.
#'    }
#'    \item \code{"ss"}: SECR with received signal strengths at traps recorded:
#'    \itemize{
#'          \item ssb0:     Signal strength at source.
#'
#'          \item ssb1:     Decrease in signal strength per unit distance due to sound
#'                          propagation.
#'
#'          \item sigmass:  Error term associated with the normal distribution used to model signal strength.
#'    }
#'    \item \code{"sstoa"}: SECR with precise TOA and received signal strengths at traps
#'      recorded:
#'    \itemize{
#'          \item sigmatoa: As above.
#'
#'          \item ssb0:     As above.
#'
#'          \item ssb1:     As above.
#'
#'          \item sigmass:  As above.
#'    }
#'    \item \code{"dist"}: SECR with estimated distances between animals
#'      and traps at which detections occurred:
#'    \itemize{
#'          \item alpha:    Shape parameter associated with the gamma distribution
#'                          used to model estimated distances.
#'    }
#'    \item \code{"angdist"}: SECR with estimates of angle and distance to animal recorded:
#'    \itemize{
#'          \item kappa:    As above.
#'
#'          \item alpha:    As above.
#'    }
#'    \item \code{"mrds"}: Mark-recapture distance sampling. Equivalent to SECR, but with known animal
#'      locations. No additional parameters.
#'    \item \code{"ssmrds"}: Mark-recapture distance sampling with signal strength information:
#'    \itemize{
#'          \item ssb0:     As above.
#'
#'          \item ssb1:     As above.
#'
#'          \item sigmass:  As above.
#'    }
#' }
#' Possible detection functions, along with their parameters, are as follows:
#'
#' \itemize{
#'     \item \code{"hn"}: Half-normal detection function:
#'   \itemize{
#'          \item g0:       Probability of detection at distance 0.
#'
#'          \item sigma:    Scale parameter.
#'   }
#'    \item \code{"hr"}: Hazard rate detection function:
#'    \itemize{
#'          \item g0
#'
#'          \item sigma
#'
#'          \item z
#'    }
#'    \item \code{"th"}: Threshold detection function:
#'    \itemize{
#'          \item shape
#'
#'          \item scale
#'    }
#'    \item \code{"logth"}: Log-link threshold detection function:
#'    \itemize{
#'          \item shape1
#'
#'          \item shape2
#'
#'          \item scale
#'    }
#' }
#' @param capt an array of dimension \code{(n, S, K)}, where \code{n} is the number of
#' detected animals, \code{S} is number of individual sampling sessions, and \code{K}
#' is the number of deployed traps. The object returned by  \code{make.capthist()} is
#' suitable if \code{method} is \code{"simple"}. Otherwise, the \code{1} values in
#' this array must be changed to the value of the recorded supplementary information,
#' which will depend on \code{method} (see 'Details'). When \code{method} is
#' \code{"sstoa"}, \code{"mrds"}, or \code{"ssmrds"} this array must be of dimension
#' \code{(n, S, K, 2)}. With joint supplementary information (\code{"sstoa"} or
#' \code{"angdist"}), \code{capt[, , , 1]} and \code{capt[, , , 2]} each provide the
#' different types of supplementary information, the order of which is alphabetical (also
#' given by the order indicated in the method name, for example for method \code{"sstoa"},
#' \code{capt[, , , 1]} and \code{capt[, , , 2]} provide the signal strength and time of
#' arrival information, respectively). With \code{"mrds"} and \code{"ssmrds"},
#' \code{capt[, , , 1]} provides either binary capture history array or signal strength
#' capture history information (respectively) and \code{capt[, , , 2]} provides the
#' distances between all traps (regardless of capture) and detected animals.
#' @param traps a matrix containing the coordinates of trap locations. The object
#' returned by \code{\link[secr]{read.traps}} is suitable, and is required for automatic
#' generation of start values.
#' @param mask a mask object. The object returned by \code{\link[secr]{make.mask}} is
#' suitable.
#' @param sv either \code{"auto"}, or a named vector. If \code{auto}, starting values for
#' all parameters are automatically generated. If a vector, the elements are the starting
#' values and the names indicate which parameter these correspond to. Starting values for
#' all parameters need not be provided; they are automatically generated for any parameters
#' that do not have a starting value explicitly provided. See 'Details' for list of
#' parameters used by each method.
#' @param bounds a list with optional components corresponding to parameters which are to
#' have their default bounds overridden. Each component should be a vector of length two
#' specifying the bounds, and the name of the component should be the name of the
#' parameter to which these bounds apply. To remove default bounds from a parameter the
#' component should be \code{NULL} rather than a vector of length two. Bounds for all
#' parameters need not be provided; if there is no component corresponding to a
#' parameter it keeps its default bounds. See 'Details' for list of parameters used by
#' each method.
#' @param fix a list with optional components corresponding to parameters which are to
#' be fixed rather than estimated. Each component should be a vector of length one,
#' specifying the fixed value of the parameter, and the name of the component should be
#' the name of the paramter to which this value applies.
#' @param ssqtoa an optional matrix. If calculated before call to \code{admbsecr},
#' providing this will prevent recalculation.
#' @param cutoff the signal strength threshold of detection. Required if \code{method} is
#' \code{"ss"} or \code{"sstoa"}.
#' @param cpi numeric vector, used for acoustic surveys only. Contains number of calls emitted
#' independently monitored individuals over the course of the survey.
#' @param sound.speed the speed of sound in metres per second. Used for TOA analysis.
#' @param admbwd file path to the ADMB working directory. Only required if
#' \code{autogen} is \code{TRUE}, in which case it points to the directory in which the
#' \code{.tpl} file is located.
#' @param method either \code{"simple"}, \code{"toa"}, \code{"ang"}, \code{"ss"}, or
#' \code{"sstoa"}. See 'Details'.
#' @param detfn the detection function to be used. Either half normal (\code{"hn"}),
#' hazard rate (\code{"hr"}), threshold (\code{"th"}) or log-link threshold (\code{"logth"}.
#' If method is \code{"ss"}, this argument gives the link function for the expected received
#' signal strengths (either \code{"identity"}, the default, or \code{"log"}).
#' @param memory value of \code{arrmblsize} in ADMB. Increase this if ADMB reports a
#' memory error.
#' @param profpars character vector of names of parameters over which profile likelihood
#' should occur. UNTESTED.
#' @param scalefactors named vector of scale factors for model parameters. ADMB works best
#' when parameters are of similar magnitudes. Setting a scale factor, \code{s}, for a
#' parameter, \code{p}, results in \code{admbsecr} dealing with \code{s*p} rather than
#' \code{p}, and should therefore be used when parameters are of different magnitudes. All
#' parameter estimates and standard errors still refer to \code{p}.
#' @param clean logical, if \code{TRUE} ADMB files are cleaned after fitting of the model.
#' @param verbose logical, if \code{TRUE} ADMB details, along with error messages, are
#' printed to the R session.
#' @param trace logical, if \code{TRUE} parameter values at each step of the fitting
#' algorithm are printed to the R session.
#' @param autogen logical, if \code{TRUE}, the appropriate \code{.tpl} file is written
#' to \code{admbwd} (or the current working directory if \code{admbwd} is \code{NULL}).
#' If \code{FALSE}, the \code{.tpl} file should already be located in \code{admbwd} (or
#' the current working directory if \code{admb} is \code{NULL}). Usually only set to
#' \code{FALSE} for development purposes.
#' @return An object of class 'admb'.
#'
#' The following functions can be used to extract model components:
#' \code{\link[base]{summary}}, \code{\link[R2admb:AIC.admb]{AIC}},
#' \code{\link[R2admb:AIC.admb]{logLik}}, \code{\link[R2admb:AIC.admb]{deviance}},
#' \code{\link[R2admb:AIC.admb]{vcov}}, \code{\link[R2admb:AIC.admb]{coef}},
#' \code{\link[R2admb:AIC.admb]{stdEr}}, and \code{\link[R2admb:AIC.admb]{confint}}.
#'
#' The latter takes arguments \code{level} and \code{method}, which specify the confidence
#' level and calculation method respectively. The default method gives quadratic (Wald)
#' intervals based on approximate standard errors; \code{"profile"} gives profile
#' likelihood intervals (UNTESTED), and can be used if the \code{admbsecr()} parameter
#' \code{profpars} is non-null and provides names of model parameters that are to be
#' profiled.
#' @author Ben Stevenson
#' @export
admbsecr <- function(capt, traps = NULL, mask, sv = "auto", bounds = NULL, fix = NULL,
                     ssqtoa = NULL, cutoff = NULL, cpi = NULL, sound.speed = 330,
                     admbwd = NULL, method = "simple", detfn = "hn" , memory = NULL,
                     profpars = NULL, scalefactors = NULL, clean = TRUE, verbose = FALSE,
                     trace = FALSE, autogen = TRUE){
  ## Warnings for incorrect input.
  if (length(method) != 1){
    stop("method must be of length 1")
  }
  if (method == "simple" & any(capt != 1 & capt != 0)){
    stop('capt must be binary when using the "simple" method')
  }
  if ((method == "ss" | method == "sstoa" | method == "ssmrds") & is.null(cutoff)){
    stop("cutoff must be supplied for signal strength analysis")
  }
  if (!is.array(capt) | !(length(dim(capt)) == 3 | length(dim(capt)) == 4)){
    stop("capt must be a three or four-dimensional array.")
  }
  if (dim(capt)[2] != 1){
    stop("admbsecr only currently works for a single sampling session.")
  }
  if (method == "ss" | method == "sstoa" | method == "ssmrds"){
    if (missing(detfn)){
      detfn <- "identity"
    } else if (!(detfn == "identity" | detfn == "log"))
      stop("The \"ss\", \"sstoa\" and \"ssmrds\" methods use their own detection function. \nThe 'detfn' argument can either be \"identity\" or \"log\" (see 'Details' in help file).")
  } else if (!(detfn == "hn" | detfn == "th" | detfn == "logth" | detfn == "hr")){
    stop("Detection function must be \"hn\", \"th\", \"logth\" or \"hr\"")
  }
  if (trace){
    verbose <- TRUE
  }
  if (!is.null(cpi)){
    if (length(cpi) < 2){
      stop("cpi must must be at least 2 length.")
    } else if (min(cpi) == max(cpi)){
      stop("cpi must not have variance 0.")
    }
  }
  trace <- as.numeric(trace)
  currwd <- getwd()
  ## If traps is NULL, see if it is provided as part of capt.
  if (is.null(traps)){
    traps <- traps(capt)
  }
  if (diff(range(traps[, 1])) == 0 & diff(range(traps[, 2])) == 0 & any(sv == "auto")){
    stop("All traps are at the same location; please provide starting values.")
  }
  ## Moving to ADMB working directory.
  if (!is.null(admbwd)){
    setwd(admbwd)
  }
  ## If NAs are present in capture history object, change to zeros.
  capt[is.na(capt)] <- 0
  ## Extracting no. animals trapped (n) and traps (k) from capture history array.
  ## Only currently works with one capture session.
  n <- dim(capt)[1]
  k <- dim(capt)[3]
  ## Area covered by each mask location.
  A <- attr(mask, "area")
  bincapt <- capt
  bincapt[capt > 0] <- 1
  ## Logical flag indicating whether Da needs to be fitted.
  fitDa <- !is.null(cpi)
  if (length(dim(bincapt)) == 4){
    bincapt <- bincapt[, , , 1, drop = FALSE]
  } else if (length(dim(bincapt)) > 4){
    stop("capt array cannot have more than 4 dimensions.")
  }
  ## Detection function parameters.
  detnames <- c(c("g0", "sigma")[detfn == "hn" | detfn == "hr"],
                c("shape", "scale")[detfn == "th"],
                c("shape1", "shape2", "scale")[detfn == "logth"],
                "z"[detfn == "hr"])
  ## Parameter names.
  parnames <- c("D"[!fitDa], "Da"[fitDa], "muC"[fitDa], "sigmaC"[fitDa], detnames,
                c("ssb0", "ssb1", "sigmass")[method == "ss" | method == "sstoa" | method == "ssmrds"],
                "sigmatoa"[method == "toa" | method == "sstoa"],
                "kappa"[method == "ang" | method == "angdist"],
                "alpha"[method == "dist" | method == "angdist"])
  ## Setting number of model parameters.
  npars <- length(parnames)
  ## Setting up bounds.
  default.bounds <- list(D = c(0, 1e8),
                         Da = c(0, 1e8),
                         muC = c(0, 1e8),
                         sigmaC = c(0, 1e5),
                         g0 = c(0, 1),
                         sigma = c(0, 1e5),
                         shape = NULL,
                         shape1 = c(0, 1e5),
                         shape2 = NULL,
                         scale = c(0, 1e5),
                         ssb0 = NULL,
                         ssb1 = c(0, 10),
                         sigmass = c(0, 1e5),
                         z = c(0, 1e5),
                         sigmatoa = c(0, 1e5),
                         kappa = c(0, 700),
                         alpha = c(0, 10000))[parnames]
  if (!(is.list(bounds) | is.null(bounds))){
    stop("bounds must either be NULL or a list.")
  } else {
    bound.changes <- bounds
    bounds <- default.bounds
    for (i in names(default.bounds)){
      if (i %in% names(bound.changes)){
        bounds[[i]] <- bound.changes[[i]]
      } else {
        ## Removing NULL elements from list.
        bounds[[i]] <- bounds[[i]]
      }
    }
  }
  ## If sv is a list, turn it into a vector.
  if (is.list(sv)){
    sv <- c(sv, recursive = TRUE)
  }
  ## Setting sv to a vector full of "auto" if required.
  if (length(sv) == 1 & sv[1] == "auto"){
    sv <- rep("auto", npars)
    names(sv) <- parnames
  } else if (is.null(names(sv))){
    stop("sv is not a named vector.")
  } else if (length(unique(names(sv))) != length(names(sv))){
    stop("sv names are not all unique")
  } else {
    ## Warning if a listed parameter name is not used in this model.
    if (!all(names(sv) %in% parnames)){
      warning("One of the element names of sv is not a parameter used in this model.")
    }
    sv.old <- sv
    sv <- rep("auto", npars)
    names(sv) <- parnames
    for (i in parnames){
      if (any(names(sv.old) == i)){
        sv[i] <- sv.old[i]
      }
    }
    ## Reordering sv vector.
    sv <- sv[parnames]
  }
  ## Adding fixed parameters to "sv" in case they are required for
  ## determining further start values.
  for (i in names(fix)){
    sv[i] <- fix[[i]]
  }
  autofuns <- list("D" = autoD, "Da" = autoDa, "muC" = automuC, "sigmaC" = autosigmaC,
                   "g0" = autog0, "sigma" = autosigma,
                   "shape" = autoshape, "shape1" = autoshape1, "shape2" = autoshape2,
                   "scale" = autoscale, "z" = autoz,
                   "ssb0" = autossb0, "ssb1" = autossb1,
                   "sigmass" = autosigmass, "sigmatoa" = autosigmatoa,
                   "kappa" = autokappa, "alpha" = autoalpha)
  ## Replacing "auto" elements of sv vector.
  for (i in rev(which(sv == "auto"))){
    sv[i] <- autofuns[[names(sv)[i]]](capt, bincapt, traps, mask, sv, cutoff, method, detfn, cpi)
  }
  sv <- as.numeric(sv)
  ## Removing attributes from capt and mask objects as do_admb cannot handle them.
  bincapt <- matrix(as.vector(bincapt), nrow = n, ncol = k)
  capt <- array(as.vector(capt), dim = c(n, k, dim(capt)[4][length(dim(capt)) == 4]))
  mask.obj <- mask
  mask <- as.matrix(mask)
  ## No. of mask locations.
  nm <- nrow(mask)
  traps.obj <- traps
  traps <- as.matrix(traps)
  ## Distances between traps and mask locations.
  dist <- distances(traps, mask)
  ## Sorting out scale factors
  if (!is.null(scalefactors)){
    fs <- names(scalefactors) %in% names(fix)
    if (any(fs)){
      scalefactors <- scalefactors[!fs]
      warning("Scale factors that are specified for fixed parameters are being ignored.")
    }
    ms <- names(scalefactors %in% parnames)
    if (!all(ms)){
      scalefactors <- scalefactors[ms]
      warning("Scale factors are specified for unmodelled parameters. These are being ignored.")
    }
  }
  ## Setting sigmatoa scale factor.
  if ("sigmatoa" %in% parnames & !("sigmatoa" %in% names(fix))){
    if (is.null(scalefactors)){
      scalefactors <- c(sigmatoa = 1000)
    } else {
      if (is.na(scalefactors["sigmatoa"])){
        scalefactors <- c(scalefactors, sigmatoa = 1000)
      }
    }
  }
  ## Creating .tpl file.
  if (autogen){
    prefix <- "secr"
    make.all.tpl.easy(memory = memory, method = method, detfn = detfn,
                      parnames = parnames, scalefactors = scalefactors,
                      cpi = cpi)
    bessel.exists <- file.access("bessel.cxx", mode = 0)
    if (bessel.exists == -1){
      make.bessel()
    }
  } else {
    prefix <- paste(method, "secr", sep = "")
  }
  ## Setting up data for do_admb.
  if (method == "simple"){
    data <- list(n = n, ntraps = k, nmask = nm, A = A, capt = capt,
                 dist = dist, trace = trace)
  } else if (method == "toa"){
    if (is.null(ssqtoa)){
      ssqtoa <- apply(capt, 1, toa.ssq, dists = dist, speed = sound.speed)
    }
    data <- list(n = n, ntraps = k, nmask = nm, A = A, toacapt = capt,
                 toassq = t(ssqtoa), dist = dist, capt = bincapt, trace = trace)
  } else if (method == "ang"){
    angs <- angles(traps, mask)
    data <- list(n = n, ntraps = k, nmask = nm, A = A, angcapt = capt,
                 ang = angs, dist = dist, capt = bincapt, trace = trace)
  } else if (method == "ss"){
    data <- list(n = n, ntraps = k, nmask = nm, A = A, c = cutoff, sscapt = capt,
                 dist = dist, capt = bincapt, trace = trace)
  } else if (method == "sstoa"){
    if (is.null(ssqtoa)){
      ssqtoa <- apply(capt[, , 2], 1, toa.ssq, dists = dist, speed = sound.speed)
    }
    data <- list(n = n, ntraps = k, nmask = nm, A = A, c = cutoff, sscapt = capt[, , 1],
                 toacapt = capt[, , 2], toassq = t(ssqtoa), dist = dist, capt = bincapt,
                 trace = trace)
  } else if (method == "dist"){
    data <- list(n = n, ntraps = k, nmask = nm, A = A, distcapt = capt, dist = dist,
                 capt = bincapt, trace = trace)
  } else if (method == "angdist"){
    angs <- angles(traps, mask)
    data <- list(n = n, ntraps = k, nmask = nm, A = A, angcapt = capt[, , 1],
                 distcapt = capt[, , 2], ang = angs, dist = dist, capt = bincapt,
                 trace = trace)
  } else if (method == "mrds"){
    data <- list(n = n, ntraps = k, nmask = nm, A = A, capt = capt[, , 1],
                 dist = dist, indivdist = capt[, , 2], trace = trace)
  } else if (method == "ssmrds"){
    data <- list(n = n, ntraps = k, nmask = nm, A = A, c = cutoff, sscapt = capt[, , 1],
                 dist = dist, capt = bincapt, indivdist = capt[, , 2], trace = trace)
  } else {
    stop('method must be either "simple", "toa", "ang", "ss", "sstoa", "dist", or "mrds"')
  }
  if (fitDa){
    data$cpi <- cpi
    data$nr <- length(cpi)
  }
  params <- list()
  for (i in 1:npars){
    params[[i]] <- sv[i]
  }
  names(params) <- parnames
  ## Removing fixed parameters from param list and adding them to the data instead.
  for (i in names(fix)){
    params[[i]] <- NULL
    bounds[[i]] <- NULL
    data[[i]] <- fix[[i]]
  }
  ## Fitting the model.
  if (!is.null(profpars)){
    fit <- do_admb(prefix, data = data, params = params, bounds = bounds, verbose = verbose,
                   profile = TRUE, profile.opts = list(parsvector = profpars), safe = FALSE,
                   run.opts = run.control(checkdata = "write", checkparam = "write",
                     clean_files = clean))
  } else {
    fit <- do_admb(prefix, data = data, params = params, bounds = bounds, verbose = verbose,
                   safe = FALSE, run.opts = run.control(checkdata = "write",
                                   checkparam = "write", clean_files = clean))
  }
  if (autogen){
    file.remove("secr.tpl")
    if (bessel.exists == -1){
      file.remove("bessel.cxx")
    }
  }
  setwd(currwd)
  fit$data <- data
  fit$traps <- traps.obj
  fit$mask <- mask.obj
  fit$bounds <- bounds
  fit$fix <- fix
  fit$sound.speed <- sound.speed
  fit$memory <- memory
  fit$scalefactors <- scalefactors
  fit$method <- method
  fit$detfn <- detfn
  fit$parnames <- parnames
  class(fit) <- c(class(fit), method, detfn, "admbsecr")
  if (fit$maxgrad < -1){
    stop("Maximum gradient component is large, run with trace = TRUE and look for runaway parameters.")
  }
  fit
}

#' Fitting SECR models in ADMB
#'
#' Fits an SECR model, with our without supplementary information
#' relevant to animal location. Parameter estimation is done by
#' maximum likelihood through and ADMB executible.
#'
#' @param capt A list with named components, containing the capture
#' history and supplementary information.
#' @param traps A matrix with two columns. The rows provide Cartesian
#' coordinates for trap locations.
#' @param mask A matrix with two columns. The rows provide Cartesian
#' coordinates for the mask point locations.
#' @param detfn A character string specifying the detection function
#' to be used. Options are "hn" (halfnormal), "hr" (hazard rate), "th"
#' (threshold), "lth" (log-link threshold), "ss" (signal strength), or
#' "logss" (log-link signal strength). If either of the latter two are
#' used, signal strength information must be provided in \code{capt}.
#' @param sv A named list. Component names are parameter names, and
#' each component is a start value for the associated parameter.
#' @param bounds A named list. Component names are parameter names,
#' and each components is a vector of length two, specifying the
#' bounds for the associated parameter.
#' @param fix A named list. Component names are parameter names to be
#' fixed, and each component is the fixed value for the associated
#' parameter.
#' @param scalefactors A named list. Component names are parameter
#' names, and each components is a scalefactor for the associated
#' parameter.
#' @param trace logical, if \code{TRUE} parameter values at each step
#' of the optimisation algorithm are printed to the R session.
#'
#'
admbsecr2 <- function(capt, traps, mask, detfn = "hn", sv = NULL, bounds = NULL,
                      fix = NULL, scalefactors = NULL, trace = FALSE){
  capt.bin <- capt$bincapt
  if (is.null(capt.bin)){
    stop("The binary capture history must be provided as a component of 'capt'.")
  }
  if (!is.list(sv) & !is.null(sv)){
    stop("The 'sv' argument must be 'NULL' or a list")
  }
  if (!is.list(bounds) & !is.null(bounds)){
    stop("The 'bounds' argument must be 'NULL' or a list")
  }
  if (!is.list(fix) & !is.null(fix)){
    stop("The 'fix' argument must be 'NULL' or a list")
  }
  n <- nrow(capt.bin)
  n.traps <- nrow(traps)
  n.mask <- nrow(mask)
  A <- attr(mask, "area")
  dist <- distances(traps, mask)
  detfns <- c("hn", "hr", "th", "lth", "ss", "logss")
  detfn.id <- which(detfn == detns)
  detpar.names <- switch(detfn,
                         hn = c("g0", "sigma"),
                         hr = c("g0", "sigma", "z"),
                         th = c("shape", "scale"),
                         lth = c("shape1", "shape2", "scale"),
                         ss = c("b0.ss", "b1.ss", "sigma.ss"),
                         logss = c("b0.ss", "b1.ss", "sigma.ss"))
  ## TODO: Sort out how to determine supplementary parameter names.
  suppar.names <- NULL
  par.names <- c("D", detpar.names, suppar.names)
  n.detpars <- length(detpar.names)
  n.suppars <- length(suppar.names)
  npars <- length(par.names)
  ## Sorting out start values.
  sv.old <- sv
  sv <- vector("list", length = npars)
  names(sv) <- par.names
  sv[names(sv.old)] <- sv.old
  sv[names(fix)] <- fix
  auto.names <- par.names[!names(sv) %in% names(sv.old)]
  sv.funs <- paste("auto", auto.names, "2", sep = "")
  for (i in seq(1, length(auto.names), length.out = length(auto.names))){
    sv[auto.names[i]] <- eval(call(sv.funs[i], capt, bincapt, traps, mask,
                                   sv, cutoff, method, detfn, cpi))
  }
  ## Sorting out phases.
  phases <- vector("list", length = npars)
  for (i in par.names){
    if (any(i == names(fix))){
      phases[[i]] <- -1
    } else {
      phases[[i]] <- 0
    }
  }
  D.phase <- phases[["D"]]
  detpars.phase <- c(phases[detpar.names], recursive = TRUE)
  suppars.phase <- c(phases[suppar.names], recursive = TRUE)
  ## Sorting out bounds.
  default.bounds <- list(D = c(0, 1e8),
                         Da = c(0, 1e8),
                         muC = c(0, 1e8),
                         sigmaC = c(0, 1e5),
                         g0 = c(0, 1),
                         sigma = c(0, 1e5),
                         shape = c(-1e8, 1e8),
                         shape1 = c(0, 1e5),
                         shape2 = c(-1e8, 1e8),
                         scale = c(0, 1e5),
                         ssb0 = c(0, 1e8),
                         ssb1 = c(0, 10),
                         sigmass = c(0, 1e5),
                         z = c(0, 1e5),
                         sigmatoa = c(0, 1e5),
                         kappa = c(0, 700),
                         alpha = c(0, 10000))[par.names]
  bound.changes <- bounds
  bounds <- default.bounds
  for (i in names(default.bounds)){
    if (i %in% names(bound.changes)){
      bounds[[i]] <- bound.changes[[i]]
    }
  }
  D.bounds <- bounds[["D"]]
  D.lb <- D.bounds[1]
  D.ub <- D.bounds[2]
  detpar.bounds <- bounds[detpar.names]
  detpars.lb <- sapply(detpar.bounds, function(x) x[1])
  detpars.ub <- sapply(detpar.bounds, function(x) x[2])
  suppar.bounds <- bounds[suppar.names]
  suppars.lb <- sapply(suppar.bounds, function(x) x[1])
  suppars.ub <- sapply(suppar.bounds, function(x) x[2])
  ## Sorting out scalefactors.
  sf <- vector("list", length = npars)
  for (i in par.names){
    sf[i] <- ifelse(i %in% names(scalefactors), scalefactors[i], 1)
  }
  D.sf <- sf[["D"]]
  detpars.sf <- c(sf[detpar.names], recursive = TRUE)
  suppars.sf <- c(sf[suppar.names], recursive = TRUE)
  dbl.min <- 1e-150
  ## Some stuff being set as defaults for testing.
  n.freqs <- 1
  call.freqs <- 1
  fit.angs <- 0
  fit.dists <- 0
  fit.ss <- 0
  fit.toas <- 0
  fit.mrds <- 0
  capt.ang <- ifelse(fit.angs, capt$ang, 0)
  capt.dist <- ifelse(fit.dist, capt$dist, 0)
  capt.ss <- ifelse(fit.ss, capt$ss, 0)
  capt.toa <- ifelse(fit.toa, capt$toa, 0)
  mrds.dist <- ifelse(fit.mrds, capt$mrds, 0)
  ###
  dists <- distances(traps, mask)
  data.list <- list(D.lb, D.ub, D.phase, D.sf, n.detpars, detpars.lb,
                    detpars.ub, detpars.phase, detpars.sf, n.suppars,
                    suppars.lb, suppars.ub, suppars.phase, suppars.sf,
                    detfn.id, as.numeric(trace), dbl.min, n, n.traps,
                    n.mask, A, n.freqs, call.freqs, capt.bin,
                    fit.angs, capt.ang, fit.dists, capt.dist, fit.ss,
                    capt.ss, fit.toas, capt.toa, fit.mrds, mrds.dist,
                    dists)
  write_pin("secr", list(sv))
  write_dat("secr", data.list)
}
