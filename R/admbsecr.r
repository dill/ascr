#' Fitting SECR models in ADMB
#'
#' Fits an SECR model, with our without supplementary information
#' relevant to animal location. Parameter estimation is done by
#' maximum likelihood through an AD Model Builder (ADMB) executable.
#'
#' ADMB uses a quasi-Newton method to find maximum likelihood
#' estimates for the model parameters. Standard errors are calculated
#' by taking the inverse of the negative of the Hessian.
#'
#' Alternatively, \link{boot.admbsecr} can be used to carry out a
#' parametric bootstrap procedure, from which parameter uncertainty
#' can also be inferred.
#'
#' If the data are from an acoustic survey where individuals call more
#' than once (i.e., the argument \code{call.freqs} contains values
#' that are not 1), then standard errors calculated from the inverse
#' of the negative Hessian are not correct. They are therefore not
#' provided in this case. The method used by the function
#' \link{boot.admbsecr} is currently the only way to calculate these
#' reliably (see Stevenson et al., in prep., for details).
#'
#' @section The \code{capt} argument:
#' The \code{capt} argument is a list with named components. Each
#' component must be an \eqn{n} by \eqn{k} matrix, where \eqn{n} is
#' the number of detections made, and \eqn{k} is the number of traps
#' (or detectors) deployed. A component named \code{bincapt} is
#' compulsory.
#'
#' Further optional component names each refer to a type of
#' information which is informative on animal location collected on
#' each detection. Possible choices are: \code{bearing}, \code{dist},
#' \code{ss}, \code{toa}, and \code{mrds}.
#'
#' If the \eqn{i}th individual evaded the \eqn{j}th trap (or
#' detector), then the \eqn{j}th element in the \eqn{i}th row should
#' be 0 for all components. Otherwise, if the \eqn{i}th individual was
#' trapped (or detected) by the \eqn{j}th trap (or detector), then:
#' \itemize{
#'   \item For the \code{bincapt} component, the element should be 1.
#'   \item For the \code{bearing} component, the element should be the
#'         estimated bearing from which the detector detected the
#'         individual.
#'   \item For the \code{dist} component, the element should be the
#'         estimated distance between the individual and the detector
#'         at the time of the detection.
#'   \item For the \code{ss} component, the element should be the
#'         measured signal strength of an acoustic signal detected by
#'         the detector (only possible when the detectors are
#'         microphones).
#'   \item For the \code{toa} component, the element should be the
#'         measured time of arrival (in seconds) since the start of
#'         the survey (or some other reference time) of an acoustic
#'         signal detected by the detector (only possible when the
#'         detectors are microphones).
#'   \item For the \code{mrds} component, the element should be the
#'         \emph{known} (not estimated) distance between the individual
#'         and the detector at the time of the detection.
#' }
#'
#' @section Fitted parameters:
#'
#' The parameter \code{D}, the density of individuals (or, in an
#' acoustic survey, the density of calls) is always fitted. The
#' effective survey area, \code{esa}, (see Borchers, 2012, for
#' details) is always provided as a derived parameter, with a standard
#' error calculated using the delta method.
#'
#' Further parameters to be fitted depend on the choice of the
#' detection function (i.e., the \code{detfn} argument), and the types
#' of additional information collected (i.e., the components in the
#' \code{capt}).
#'
#' Details of the detection functions are as follows:
#'
#' For \code{detfn = "hn"}:
#' \itemize{
#'    \item Estimated paramters are \code{g0} and \code{sigma}.
#'    \item \eqn{g(d) = g_0\ exp(-d^2/(2\sigma^2))}{g(d) = g0 * exp( -d^2 / (2 * sigma^2 ))}
#' }
#'
#' For \code{detfn = "hr"}:
#' \itemize{
#'    \item Estimated parameters are \code{g0}, \code{sigma}, and
#'          \code{z}.
#'    \item \eqn{g(d) = g_0\ (1 - exp(-(d/\sigma)^{-z}))}{g(d) = g0 * ( 1 - exp( -(d/sigma)^{-z} ) )}
#' }
#'
#' For \code{detfn = "th"}:
#' \itemize{
#'   \item Estimated parameters are \code{shape}
#'         \ifelse{latex}{(\eqn{\kappa})}{} and \code{scale}
#'         \ifelse{latex}{(\eqn{\tau})}{}.
#'   \item \eqn{g(d) = 0.5 - 0.5\ erf(d/\kappa - \tau)}{g(d) = 0.5 - 0.5 * erf( d/shape - scale )}
#' }
#'
#' For \code{detfn = "ss"}:
#' \itemize{
#'   \item The signal strength detection function is special in that
#'         it requires signal strength information to be collected in
#'         order for all parameters to be estimated.
#'   \item Estimated parameters are \code{b0.ss}, \code{b1.ss}, and
#'         \code{sigma.ss}.
#'   \item The expected signal strength is modelled as:
#'         \eqn{E(SS) = h^{-1}(\beta_0 - \beta_1d)}{E(SS) = h^{-1}(b0.ss - b1.ss*d)},
#'         where \eqn{h} is specified by the argument \code{ss.link}.
#' }
#'
#' Details of the parameters associated with different additional data
#' types are as follows:
#'
#' For data type \code{"bearing"}, \code{kappa} is estimated. This is
#' the concerntration parameter of the von-Mises distribution used for
#' measurement error in estimated bearings.
#'
#' For data type \code{"dist"}, \code{alpha} is estimated. This is the
#' shape parameter of the gamma distribution used for measurement
#' error in estimated distances.
#'
#' For data type \code{"toa"}, \code{sigma.toa} is estimated. This is
#' the standard deviation parameter of the normal distribution used
#' for measurement error in recorded times of arrival.
#'
#' For data type \code{"mrds"}, no extra parameters are
#' estimated. Animal location is assumed to be known.
#'
#' @section Convergence:
#'
#' The best approach to fixing convergence issues is to re-run the
#' \code{admbsecr} function with the argument \code{trace} set to
#' \code{TRUE}. Parameter values will be printed out for each step of
#' the optimisation algorithm. Look for a large jump in a parameter to
#' a value far from what is feasible. This can be fixed by using the
#' \code{bounds} argument to restrict the parameter space over which
#' ADMB searches to maximise the likelihood.
#' 
#' @references Borchers, D. L. (2012) A non-technical overview of
#' spatially explicit capture-recapture models. \emph{Journal of
#' Ornithology}, \strong{152}: 435--444.
#'
#' @references Stevenson, B. C., Borchers, D. L., Altwegg, R., Measey,
#' G. J., Swift, R. J., and Gillespie, D. M. (in prep.) An acoustic
#' spatially explicit capture-recapture method for estimating
#' vocalizing amphibian density.
#'
#' @return A list of class \code{"admbsecr"}. Components contain
#' information such as estimated parameters and standard errors. The
#' best way to access such information, however, is through the
#' variety of helper functions provided by the admbsecr package.
#' 
#' @param capt A list with named components, containing the capture
#' history and supplementary information. See further details below.
#' @param traps A matrix with two columns. Each row provides Cartesian
#' coordinates for the location of a trap (or detector).
#' @param mask A matrix with two columns. Each row provides Cartesian
#' coordinates for the location of a mask point. The function
#' \link{create.mask} will return a suitable object.
#' @param detfn A character string specifying the detection function
#' to be used. Options are "hn" (halfnormal), "hr" (hazard rate), "th"
#' (threshold), "lth" (log-link threshold), or "ss" (signal
#' strength). If the latter is used, signal strength information must
#' be provided in \code{capt}.
#' @param sv A named list. Component names are parameter names, and
#' each component is a start value for the associated parameter. See
#' below for further details on the parameters to be fitted.
#' @param bounds A named list. Component names are parameter names,
#' and each components is a vector of length two, specifying the
#' bounds for the associated parameter.
#' @param fix A named list. Component names are parameter names to be
#' fixed, and each component is the fixed value for the associated
#' parameter.
#' @param sf A named list. Component names are parameter
#' names, and each component is a scalefactor for the associated
#' parameter. The default behaviour is to automatically select
#' scalefactors based on parameter start values.
#' @param ss.link A character string, either \code{"indentity"} or
#' \code{"log"}, which specifies the link function for the signal
#' strength detection function. Only required when \code{detfn} is
#' \code{"ss"}.
#' @param cutoff The signal strength threshold, above which sounds are
#' identified as detections. Only required when \code{detfn} is
#' \code{"ss"}.
#' @param call.freqs A vector of call frequencies collected
#' independently to an acoustic survey.
#' @param sound.speed The speed of sound in metres per second,
#' defaults to 330 (the speed of sound in air). Only used when
#' \code{"toa"} is a component name of \code{capt}. \strong{Not yet
#' implemented}.
#' @param trace Logical, if \code{TRUE} parameter values at each step
#' of the optimisation algorithm are printed to the R console.
#' @param clean Logical, if \code{TRUE} ADMB output files are removed.
#' @param exe.type Character string, either \code{"old"} or
#' \code{"new"}, depending on which executable is to be used (for
#' development purposes only; please ignore).
#'
#' @seealso \link{coef.admbsecr}, \link{stdEr.admbsecr}, and
#' \link{vcov.admbsecr} to extract estimated parameters, standard
#' errors, and the variance-covariance matrix, respectively.
#' @seealso \link{boot.admbsecr} to calculate standard errors using a
#' parametric bootstrap.
#' @seealso \link{show.detfn} to plot the estimated detection
#' function.
#' @seealso \link{locations} to plot estimated locations of particular
#' individuals or calls.
#' 
#' @examples
#' \dontrun{
#' simple.capt <- example.capt["bincapt"]
#' simple.hn.fit <- admbsecr(capt = simple.capt, traps = example.traps,
#'                           mask = example.mask, fix = list(g0 = 1))
#' simple.hr.fit <- admbsecr(capt = simple.capt, traps = example.traps,
#'                           mask = example.mask, detfn = "hr")
#' bearing.capt <- example.capt[c("bincapt", "bearing")]
#' bearing.hn.fit <- admbsecr(capt = bearing.capt, traps = example.traps,
#'                            mask = example.mask, fix = list(g0 = 1))
#' }
#' 
#' @export
#'
admbsecr <- function(capt, traps, mask, detfn = "hn", sv = NULL, bounds = NULL,
                     fix = NULL, sf = NULL, ss.link = "identity",
                     cutoff = NULL, call.freqs = NULL, sound.speed  = 330,
                     trace = FALSE, clean = TRUE, exe.type = "old"){
    arg.names <- names(as.list(environment()))
    capt.bin <- capt$bincapt
    ## Checking for bincapt.
    if (is.null(capt.bin)){
        stop("The binary capture history must be provided as a component of 'capt'.")
    }
    ## Checking for correct number of trap locations.
    if (ncol(capt.bin) != nrow(traps)){
        stop("There must be a trap location for each column in the components of 'capt'.")
    }
    ## Checking that each component of 'capt' is a matrix.
    if (any(!laply(capt, is.matrix))){
        stop("At least one component of 'capt' is not a matrix.")
    }
    ## Checking for agreement in matrix dimensions.
    if (length(capt) > 1){
        all.dims <- laply(capt, dim)
        if (any(aaply(all.dims, 2, function(x) diff(range(x))) != 0)){
            stop("Components of 'capt' object have different dimensions.")
        }
    }
    ## Various checks for other arguments.
    if (!is.list(sv) & !is.null(sv)){
        stop("The 'sv' argument must be 'NULL' or a list.")
    }
    if (!is.list(bounds) & !is.null(bounds)){
        stop("The 'bounds' argument must be 'NULL' or a list.")
    }
    if (is.list(bounds)){
        if (any(laply(bounds, length) != 2)){
            stop("Each component of 'bounds' must be a vector of length 2.")
        }
    }
    if (!is.list(fix) & !is.null(fix)){
        stop("The 'fix' argument must be 'NULL' or a list.")
    }
    ##if (!missing(sound.speed)){
    ##    stop("The 'sound.speed' argument is not yet implemented.")
    ##}
    n <- nrow(capt.bin)
    n.traps <- nrow(traps)
    n.mask <- nrow(mask)
    A <- attr(mask, "area")
    ## Removing attributes from mask.
    mask <- as.matrix(mask)
    ## TODO: Sort out how to determine supplementary parameter names.
    supp.types <- c("bearing", "dist", "ss", "toa", "mrds")
    fit.types <- supp.types %in% names(capt)
    names(fit.types) <- supp.types
    ## Logical indicators for additional information types.
    fit.bearings <- fit.types["bearing"]
    fit.dists <- fit.types["dist"]
    fit.ss <- fit.types["ss"]
    fit.toas <- fit.types["toa"]
    fit.mrds <- fit.types["mrds"]
    ## Capture histories for additional information types (if they exist)
    capt.bearing <- if (fit.bearings) capt$bearing else 0
    capt.dist <- if (fit.dists) capt$dist else 0
    capt.ss <- if (fit.ss) capt$ss else 0
    capt.toa <- if (fit.toas) capt$toa else 0
    mrds.dist <- if (fit.mrds) capt$mrds else 0
    suppar.names <- c("kappa", "alpha", "sigma.toa")[fit.types[c("bearing", "dist", "toa")]]
    if (fit.ss){
        ## Warning for failure to provide 'cutoff'.
        if (missing(cutoff)){
            stop("Argument 'cutoff' is missing.")
        }
        if (!missing(detfn) & detfn != "ss"){
            warning("Argument 'detfn' is being ignored as signal strength information is provided in 'capt'. A signal strength detection function has been fitted instead.")
        }
        if (ss.link == "identity"){
            detfn <- "ss"
            linkfn.id <- 1
        } else if (ss.link == "log"){
            detfn <- "log.ss"
            linkfn.id <- 2
        } else {
            stop("ss.link must be either \"identity\" or \"log\"")
        }
    } else {
        ## Not sure what a linkfn.id of 3 means? Probably throws an error in ADMB.
        linkfn.id <- 3
    }
    detfns <- c("hn", "hr", "th", "lth", "ss", "log.ss")
    ## Sets detection function ID number for use in ADMB:
    ## 1 = Half normal
    ## 2 = Hazard rate
    ## 3 = Threshold
    ## 4 = Log-link threshold
    ## 5 = Identity-link signal strength
    ## 6 = Log-link signal strength.
    detfn.id <- which(detfn == detfns)
    detpar.names <- switch(detfn,
                           hn = c("g0", "sigma"),
                           hr = c("g0", "sigma", "z"),
                           th = c("shape", "scale"),
                           lth = c("shape.1", "shape.2", "scale"),
                           ss = c("b0.ss", "b1.ss", "sigma.ss"),
                           log.ss = c("b0.ss", "b1.ss", "sigma.ss"))
    par.names <- c("D", detpar.names, suppar.names)
    n.detpars <- length(detpar.names)
    n.suppars <- length(suppar.names)
    npars <- length(par.names)
    ## Sorting out start values. Start values are set to those provided,
    ## or else are determined automatically from functions in
    ## autofuns.r.
    sv.old <- sv
    sv <- vector("list", length = npars)
    names(sv) <- par.names
    sv[names(sv.old)] <- sv.old
    sv[names(fix)] <- fix
    auto.names <- par.names[sapply(sv, is.null)]
    sv.funs <- paste("auto", auto.names, sep = "")
    ## Done in reverse so that D is calculated last (requires detfn parameters).
    ## D not moved to front as it should appear as the first parameter in any output.
    for (i in rev(seq(1, length(auto.names), length.out = length(auto.names)))){
        sv[auto.names[i]] <- eval(call(sv.funs[i],
                                       list(capt = capt, detfn = detfn,
                                            detpar.names = detpar.names,
                                            mask = mask, traps = traps,
                                            sv = sv, cutoff = cutoff)))
    }
    ## Sorting out phases.
    ## TODO: Add phases parameter so that these can be controlled by user.
    phases <- vector("list", length = npars)
    names(phases) <- par.names
    for (i in par.names){
        if (any(i == names(fix))){
            ## Phase of -1 in ADMB fixes parameter at starting value.
            phases[[i]] <- -1
        } else {
            phases[[i]] <- 0
        }
    }
    D.phase <- phases[["D"]]
    detpars.phase <- c(phases[detpar.names], recursive = TRUE)
    if (n.suppars > 0){
        suppars.phase <- c(phases[suppar.names], recursive = TRUE)
    } else {
        suppars.phase <- -1
    }
    ## Sorting out bounds.
    ## Below bounds are the defaults.
    default.bounds <- list(D = c(0, 1e8),
                           D.a = c(0, 1e8),
                           mu.C = c(0, 1e8),
                           sigma.C = c(0, 1e5),
                           g0 = c(0, 1),
                           sigma = c(0, 1e5),
                           shape = c(-1e8, 1e8),
                           shape.1 = c(0, 1e5),
                           shape.2 = c(-1e8, 1e8),
                           scale = c(0, 1e5),
                           b0.ss = c(0, 1e8),
                           b1.ss = c(0, 10),
                           sigma.ss = c(0, 1e5),
                           z = c(0, 1e5),
                           sigma.toa = c(0, 1e5),
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
    if (n.suppars > 0){
        suppar.bounds <- bounds[suppar.names]
        suppars.lb <- sapply(suppar.bounds, function(x) x[1])
        suppars.ub <- sapply(suppar.bounds, function(x) x[2])
    } else {
        suppars.lb <- 0
        suppars.ub <- 0
    }
    ## Sorting out scalefactors.
    ## TODO: Sort these out in a better way.
    if (is.null(sf)){
        sv.vec <- c(sv, recursive = TRUE)
        ## Currently, by default, the scalefactors are the inverse
        ## fraction of each starting value to the largest starting
        ## value. Not sure how sensible this is.
        sf <- max(sv.vec)/sv.vec
    } else {
        sf <- numeric(npars)
        names(sf) <- par.names
        for (i in par.names){
            sf[i] <- ifelse(i %in% names(sf), sf[[i]], 1)
        }
    }
    D.sf <- sf[["D"]]
    detpars.sf <- c(sf[detpar.names], recursive = TRUE)
    if (n.suppars > 0){
        suppars.sf <- c(sf[suppar.names], recursive = TRUE)
    } else {
        suppars.sf <- 1
    }
    ## Setting small number so that numerical under/overflow in ADMB
    ## does not affect estimation.
    dbl.min <- 1e-150
    ## Calculating distances and angles.
    ## TODO: Try calculating these in the PROCEDURE_SECTION instead.
    dists <- distances(traps, mask)
    if (fit.bearings){
        bearings <- bearings(traps, mask)
    } else {
        bearings <- 0
    }
    if (fit.toas){
        toa.ssq <- make_toa_ssq(capt$toa, dists)
    } else {
        toa.ssq <- 0
    }
    if (is.null(cutoff)){
        cutoff <- 0
    }
    ## Kludge to fix number of parameters for no supplementary
    ## information.
    if (n.suppars == 0){
        n.suppars <- max(c(n.suppars, 1))
        sv$dummy <- 0
    }
    ## Stuff for the .dat file.
    data.list <- list(D_lb = D.lb, D_ub = D.ub, D_phase = D.phase, D_sf
                      = D.sf, n_detpars = n.detpars, detpars_lb =
                      detpars.lb, detpars_ub = detpars.ub, detpars_phase
                      = detpars.phase, detpars_sf = detpars.sf,
                      n_suppars = n.suppars, suppars_lb = suppars.lb,
                      suppars_ub = suppars.ub, suppars_phase =
                      suppars.phase, suppars_sf = suppars.sf, detfn_id =
                      detfn.id, trace = as.numeric(trace), DBL_MIN =
                      dbl.min, n = n, n_traps = n.traps, n_mask =
                      n.mask, A = A, capt_bin = capt.bin, fit_angs =
                      as.numeric(fit.bearings), capt_ang = capt.bearing,
                      fit_dists = as.numeric(fit.dists), capt_dist =
                      capt.dist, fit_ss = as.numeric(fit.ss), cutoff =
                      cutoff, linkfn_id = linkfn.id, capt_ss = capt.ss,
                      fit_toas = as.numeric(fit.toas), capt_toa =
                      capt.toa, fit_mrds = as.numeric(fit.mrds),
                      mrds_dist = mrds.dist, dists = dists, angs = bearings,
                      toa_ssq = toa.ssq)
    ## Idea of running executable as below taken from glmmADMB.
    ## Working out correct command to run from command line.
    if (exe.type == "new"){
        exe.name <- "./secr_new"
        out.name <- "secr_new"
    } else if (exe.type == "old"){
        exe.name <- "./secr"
        out.name <- "secr"
    } else {
        stop("Argument 'exe.type' must be \"old\" or \"new\".")
    }
    if (.Platform$OS == "windows"){
        os.type <- "windows"
        cmd <- "secr -ind secr.dat -ainp secr.pin"
    } else if (.Platform$OS == "unix"){
        if (Sys.info()["sysname"] == "Linux"){
            os.type <- "linux"
        } else if (Sys.info()["sysname"] == "Darwin"){
            os.type <- "mac"
        } else {
            stop("Unknown OS type.")
        }
        cmd <- paste(exe.name, "-ind secr.dat -ainp secr.pin")
    } else {
        stop("Unknown OS type.")
    }
    ## Finding executable folder (possible permission problems?).
    exe.dir <- paste(system.file(package = "admbsecr"), "ADMB", "bin", os.type, sep = "/")
    curr.dir <- getwd()
    ## Moving to executable location.
    setwd(exe.dir)
    curr.files <- list.files()
    ## Creating .pin and .dat files.
    write_pin("secr", sv)
    write_dat("secr", data.list)
    ## Running ADMB executable.
    system(cmd, ignore.stdout = !trace)
    ## Reading in model results.
    out <- read.admbsecr(out.name)
    ## Cleaning up files.
    all.files <- list.files()
    new.files <- all.files[!all.files %in% curr.files]
    if (clean){
        file.remove(new.files)
    } else {
        cat("ADMB files found in:", "\n", getwd(), "\n")
    }
    ## Warning for non-convergence.
    if (out$maxgrad < -0.1){
        warning("Failed convergence -- maximum gradient component is large.")
    }
    ## Moving back to original working directory.
    setwd(curr.dir)
    ## Putting in correct parameter names.
    for (i in seq(1, n.detpars, length.out = n.detpars)){
        replace <- names(out$coefficients) == paste("detpars[", i, "]", sep = "")
        names(out$coefficients)[replace] <- names(out$se)[replace] <-
            rownames(out$vcov)[replace] <- colnames(out$vcov)[replace] <-
                rownames(out$cor)[replace] <- colnames(out$cor)[replace] <-
                    detpar.names[i]
    }
    for (i in seq(1, n.suppars, length.out = n.suppars)){
        replace <- names(out$coefficients) == paste("suppars[", i, "]", sep = "")
        names(out$coefficients)[replace] <- names(out$se)[replace] <-
            rownames(out$vcov)[replace] <- colnames(out$vcov)[replace] <-
                rownames(out$cor)[replace] <- colnames(out$cor)[replace] <-
                    suppar.names[i]        
    }
    ## Adding extra components to list.
    if (detfn == "log.ss") detfn <- "ss"
    ## Putting bounds together.
    bounds <- cbind(c(D.lb, detpars.lb, suppars.lb),
                    c(D.ub, detpars.ub, suppars.ub))
    rownames(bounds) <- c("D", detpar.names,
                          "dummy"[length(suppar.names) == 0],
                          suppar.names[length(suppar.names) > 0])
    bounds <- bounds[rownames(bounds) != "dummy", ]
    bounds <- alply(bounds, 1, identity, .dims = TRUE)
    ## Putting in updated argument names.
    args <- vector(mode = "list", length = length(arg.names))
    names(args) <- arg.names
    for (i in arg.names){
        if (!is.null(get(i))){
            args[[i]] <- get(i)
        }
    }
    out$args <- args
    out$fit.types <- fit.types
    out$infotypes <- names(fit.types)[fit.types]
    out$detpars <- detpar.names
    out$suppars <- suppar.names
    out$phases <- phases
    ## Putting in call frequency information.
    if (!is.null(call.freqs)){
        fit.freqs <- TRUE
        mu.freqs <- mean(call.freqs)
        Da <- get.par(out, "D")/mu.freqs
        names.vec <- c(names(out[["coefficients"]]), "Da", "mu.freqs")
        coefs.updated <- c(out[["coefficients"]], Da, mu.freqs)
        names(coefs.updated) <- names.vec
        out[["coefficients"]] <- coefs.updated
        ## Removing ses, cor, vcov matrices.
        ses.updated <- rep(NA, length(names.vec))
        names(ses.updated) <- names.vec
        out[["se"]] <- ses.updated
        cor.updated <- matrix(NA, nrow = length(names.vec),
                              ncol = length(names.vec))
        dimnames(cor.updated) <- list(names.vec, names.vec)
        out[["cor"]] <- cor.updated
        vcov.updated <- matrix(NA, nrow = length(names.vec),
                               ncol = length(names.vec))
        dimnames(vcov.updated) <- list(names.vec, names.vec)
        out[["vcov"]] <- vcov.updated
        cat("NOTE: Standard errors not calculated; use boot.admbsecr().", "\n")
    } else {
        fit.freqs <- FALSE
    }
    out$fit.freqs <- fit.freqs
    class(out) <- c("admbsecr", "admb")
    out
}

## Roxygen code for NAMESPACE and datasets.

## Package imports for roxygenise to pass to NAMESPACE.
#' @import plyr Rcpp R2admb
#' @importFrom CircStats dvm rvm
#' @importFrom lattice wireframe
#' @importFrom matrixStats colProds
#' @importFrom secr make.capthist make.mask read.mask read.traps sim.popn
#' @useDynLib admbsecr
NULL

## Data documentation.

#' An example capture history object
#'
#' A list containing various additional information types. These data
#' were simulated using \link{sim.capt} using the trap locations in
#' \link{example.traps}.
#' @name example.capt
#' @format A list, which is the correct format for use as the
#' \code{capt} argument to the function \link{admbsecr}.
#' @usage example.capt
#' @docType data
#' @keywords datasets
NULL

#' An example mask object
#'
#' A matrix containing mask point locations. These mask point
#' locations are suitable for analysis of the data \link{example.capt}
#' using the function \link{admbsecr}.
#' @name example.mask
#' @format A matrix with two columns. Each row gives the Cartesian
#' coordinates of a mask point.
#' @usage example.mask
#' @docType data
#' @keywords datasets
NULL


#' An example traps object
#'
#' A matrix containing the trap locations used for the simulation of
#' the data \link{example.capt}. This object is suitable for use as
#' the \code{traps} argument of the function \link{admbsecr}.
#' 
#' @name example.traps
#' @format A matrix with two columns. Each row gives the Cartesian
#' coordinates of a trap.
#' @usage example.traps
#' @docType data
#' @keywords datasets
NULL

#' An example model object
#'
#' This is the model object that results when the \link{admbsecr}
#' function is run with \link{example.capt}\code{["bincapt"]},
#' \link{example.traps}, and \link{example.mask} set as the
#' arguments \code{capt}, \code{traps}, and \code{mask}, respectively.
#'
#' @name simple.hn.fit
#' @format A list of class \code{"admbsecr"}.
#' @usage simple.hn.fit
#' @docType data
#' @keywords datasets
NULL

#' An example model object
#'
#' This is the model object that results when the
#' \link{admbsecr} function is run with
#' \link{example.capt}\code{["bincapt"]},
#' \link{example.traps}, \link{example.mask}, and
#' \code{"hr"} set as the arguments \code{capt}, \code{traps},
#' \code{mask}, and \code{detfn}, respectively.
#'
#' @name simple.hr.fit
#' @format A list of class \code{"admbsecr"}.
#' @usage simple.hr.fit
#' @docType data
#' @keywords datasets
NULL

#' An example model object
#'
#' This is the model object that results when the
#' \link{admbsecr} function is run with
#' \link{example.capt}\code{[c("bincapt", "bearing"]},
#' \link{example.traps}, and \link{example.mask}
#' set as the arguments \code{capt}, \code{traps}, and \code{mask},
#' respectively.
#'
#' @name bearing.hn.fit
#' @format A list of class \code{"admbsecr"}.
#' @usage bearing.hn.fit
#' @docType data
#' @keywords datasets
NULL
