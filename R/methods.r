#' Extract admbsecr model coefficients
#'
#' Extracts estimated and derived parameters from a model fitted using
#' \link{admbsecr}.
#'
#' @param object A fitted model from \link[admbsecr]{admbsecr}.
#' @param pars A character containing a subset of \code{"all"},
#' \code{"derived"}, \code{"fitted"}, and \code{"linked"};
#' \code{"fitted"} corresponds to the parameters of interest,
#' \code{"derived"} corresponds to quantities that are functions of
#' these parameters (e.g., the effective survey area or animal density
#' from an acoustic survey), and \code{"linked"} corresponds to the
#' parameters AD Model Builder has maximised the likelihood over.
#' @param ... Other parameters (for S3 generic compatibility).
#'
#' @examples
#' coef(simple.hn.fit)
#' coef(simple.hn.fit, pars = "all")
#' coef(simple.hn.fit, pars = "derived")
#'
#' @method coef admbsecr
#' @S3method coef admbsecr
#'
#' @export
coef.admbsecr <- function(object, pars = "fitted", ...){
    if ("all" %in% pars){
        pars <- c("fitted", "derived", "linked")
    }
    if (!all(pars %in% c("fitted", "derived", "linked"))){
        stop("Argument 'pars' must contain a subset of \"fitted\", \"derived\", and \"linked\"")
    }
    par.names <- names(object$coefficients)
    which.linked <- grep("_link", par.names)
    linked <- object$coefficients[which.linked]
    which.derived <- which(par.names == "esa" | par.names == "Da")
    derived <- object$coefficients[which.derived]
    fitted <- object$coefficients[-c(which.linked, which.derived)]
    out <- mget(pars)
    names(out) <- NULL
    c(out, recursive = TRUE)
}

#' Extract the variance-covariance matrix from an admbsecr model
#' object
#'
#' Extracts the variance-covariance matrix for parameters in a model
#' fitted using \link[admbsecr]{admbsecr}.
#'
#' @inheritParams coef.admbsecr
#'
#' @examples
#' vcov(simple.hn.fit)
#' vcov(simple.hn.fit, pars = "all")
#' vcov(simple.hn.fit, pars = "derived")
#'
#' @method vcov admbsecr
#' @S3method vcov admbsecr
#'
#' @export
vcov.admbsecr <- function(object, pars = "fitted", ...){
    if ("all" %in% pars){
        pars <- c("fitted", "derived", "linked")
    }
    if (!all(pars %in% c("fitted", "derived", "linked"))){
        stop("Argument 'pars' must contain a subset of \"fitted\", \"derived\", and \"linked\"")
    }
    par.names <- names(object$coefficients)
    keep <- NULL
    which.linked <- grep("_link", par.names)
    which.derived <- which(par.names == "esa" | par.names == "Da")
    which.fitted <- (1:length(par.names))[-c(which.linked, which.derived)]
    keep <- NULL
    if ("fitted" %in% pars){
        keep <- c(keep, which.fitted)
    }
    if ("derived" %in% pars){
        keep <- c(keep, which.derived)
    }
    if ("linked" %in% pars){
        keep <- c(keep, which.linked)
    }
    object$vcov[keep, keep, drop = FALSE]
}

#' Extract the variance-covariance matrix from a bootstrapped admbsecr
#' model object
#'
#' Extracts the variance-covariance matrix for parameters in a model
#' fitted using \link[admbsecr]{admbsecr}, with a bootstrap procedure
#' carried out using \link[admbsecr]{boot.admbsecr}.
#'
#' @inheritParams coef.admbsecr
#'
#' @method vcov admbsecr.boot
#' @S3method vcov admbsecr.boot
#'
#' @export
vcov.admbsecr.boot <- function(object, pars = "fitted", ...){
    if ("all" %in% pars){
        pars <- c("fitted", "derived", "linked")
    }
    if (!all(pars %in% c("fitted", "derived", "linked"))){
        stop("Argument 'pars' must contain a subset of \"fitted\", \"derived\", and \"linked\"")
    }
    par.names <- names(object$coefficients)
    keep <- NULL
    which.linked <- grep("_link", par.names)
    which.derived <- which(par.names == "esa" | par.names == "Da")
    which.fitted <- (1:length(par.names))[-c(which.linked, which.derived)]
    keep <- NULL
    if ("fitted" %in% pars){
        keep <- c(keep, which.fitted)
    }
    if ("derived" %in% pars){
        keep <- c(keep, which.derived)
    }
    if ("linked" %in% pars){
        keep <- c(keep, which.linked)
    }
    object$boot.vcov[keep, keep, drop = FALSE]
}

#' Extract standard errors from an admbsecr model fit
#'
#' Extracts standard errors for estimated and derived parameters from
#' a model fitted using \link[admbsecr]{admbsecr}.
#'
#' @inheritParams coef.admbsecr
#'
#' @examples
#' stdEr(simple.hn.fit)
#' stdEr(simple.hn.fit, pars = "all")
#' stdEr(simple.hn.fit, pars = "derived")
#'
#' @method stdEr admbsecr
#' @S3method stdEr admbsecr
#'
#' @export
stdEr.admbsecr <- function(object, pars = "fitted", ...){
    if ("all" %in% pars){
        pars <- c("fitted", "derived", "linked")
    }
    if (!all(pars %in% c("fitted", "derived", "linked"))){
        stop("Argument 'pars' must contain a subset of \"fitted\", \"derived\", and \"linked\"")
    }
    par.names <- names(object$coefficients)
    which.linked <- grep("_link", par.names)
    linked <- object$se[which.linked]
    which.derived <- which(par.names == "esa" | par.names == "Da")
    derived <- object$se[which.derived]
    fitted <- object$se[-c(which.linked, which.derived)]
    out <- mget(pars)
    names(out) <- NULL
    c(out, recursive = TRUE)
}

#' Extract standard errors from a bootstrapped admbsecr model object
#'
#' Extracts standard errors for parameters in a model fitted using
#' \link[admbsecr]{admbsecr}, with a bootstrap procedure carried out
#' using \link[admbsecr]{boot.admbsecr}.
#'
#' @inheritParams coef.admbsecr
#'
#' @method stdEr admbsecr.boot
#' @S3method stdEr admbsecr.boot
#'
#' @export
stdEr.admbsecr.boot <- function(object, pars = "fitted", ...){
    if ("all" %in% pars){
        pars <- c("fitted", "derived", "linked")
    }
    if (!all(pars %in% c("fitted", "derived", "linked"))){
        stop("Argument 'pars' must contain a subset of \"fitted\", \"derived\", and \"linked\"")
    }
    par.names <- names(object$coefficients)
    which.linked <- grep("_link", par.names)
    linked <- object$boot.se[which.linked]
    which.derived <- which(par.names == "esa" | par.names == "Da")
    derived <- object$boot.se[which.derived]
    fitted <- object$boot.se[-c(which.linked, which.derived)]
    out <- mget(pars)
    names(out) <- NULL
    c(out, recursive = TRUE)
}

#' Extract AIC from an admbsecr model object
#'
#' Extracts the AIC from an admbsecr model object.
#'
#' If the model is based on an acoustic survey where there are
#' multiple calls per individual, then AIC should not be used for
#' model selection. This function therefore returns NA in this case.
#'
#' @inheritParams coef.admbsecr
#' @inheritParams stats::AIC
#'
#' @method AIC admbsecr
#' @S3method AIC admbsecr
#'
#' @export
AIC.admbsecr <- function(object, ..., k = 2){
    if (object$fit.freqs){
        out <- NA
    } else {
        out <- deviance(object) + k*length(coef(object))
    }
    out
}

#' Summarising admbsecr model fits
#'
#' Provides a useful summary of the model fit.
#'
#' @inheritParams coef.admbsecr
#'
#' @method summary admbsecr
#' @S3method summary admbsecr
#'
#' @export
summary.admbsecr <- function(object, ...){
    coefs <- coef(object, "fitted")
    derived <- coef(object, "derived")
    coefs.se <- stdEr(object, "fitted")
    derived.se <- stdEr(object, "derived")
    out <- list(coefs = coefs, derived = derived, coefs.se = coefs.se,
                derived.se = derived.se)
    class(out) <- c("summary.admbsecr", class(out))
    out
}
#' Printing admbsecr summaries
#'
#' @param x An object of class \code{summary.admbsecr}.
#' @inheritParams coef.admbsecr
#'
#' @method print summary.admbsecr
#' @S3method print summary.admbsecr
print.summary.admbsecr <- function(x, ...){
    n.coefs <- length(x$coefs)
    n.derived <- length(x$derived)
    mat <- matrix(0, nrow = n.coefs + n.derived + 1, ncol = 2)
    mat[1:n.coefs, 1] <- c(x$coefs)
    mat[1:n.coefs, 2] <- c(x$coefs.se)
    mat[n.coefs + 1, ] <- NA
    mat[(n.coefs + 2):(n.coefs + n.derived + 1), ] <- c(x$derived, x$derived.se)
    rownames(mat) <- c(names(x$coefs), "---", names(x$derived))
    colnames(mat) <- c("Estimate", "Std. Error")
    cat("Coefficients:", "\n")
    printCoefmat(mat, na.print = "")
}

#' Confidence intervals for admbsecr model parameters
#'
#' Computes confidence intervals for one or more parameters estimated
#' in an admbsecr model object.
#'
#' Options for the argument \code{method} are as follows:
#' \code{"default"} for intervals based on a normal approximation
#' using the calculated standard errors (for objects of class
#' \code{admbsecr.boot}, these standard errors are calculated from the
#' bootstrap procedure); "linked" for intervals that are calculated on
#' the parameters' link scales, then transformed back onto their
#' "real" scales; and \code{"percentile"} for intervals calculated
#' using the bootstrap percentile method (for objects of class
#' \code{admbsecr.boot} only).
#'
#' @param parm A character vector specifying which parameters are to
#' be given confidence intervals.
#' @param method A character string specifying the method used to
#' calculate the confidence intervals. See 'Details' below.
#' @inheritParams coef.admbsecr
#' @inheritParams stats::confint
#'
#' @method confint admbsecr
#' @S3method confint admbsecr
confint.admbsecr <- function(object, parm = "fitted", level = 0.95, ...){
    if (object$fit.freqs){
        stop("Standard errors not calculated; use boot.admbsecr()")
    }
    calc.cis(object, parm, level, method = "default", ...)
}


#'

#'
#' @rdname confint.admbsecr
#' @method confint admbsecr.boot
#' @S3method confint admbsecr.boot
confint.admbsecr.boot <- function(object, parm = "fitted", level = 0.95, method = "default", ...){
    calc.cis(object, parm, level, method, ...)
}

calc.cis <- function(object, parm, level, method, ...){
    if (parm == "all" | parm == "derived" | parm == "fitted"){
        parm <- names(coef(object, pars = parm))
    }
    if (method == "default"){
        mat <- cbind(coef(object, pars = "all")[parm],
                     stdEr(object, pars = "all")[parm])
        FUN.default <- function(x, level){
            x[1] + qnorm((1 - level)/2)*c(1, -1)*x[2]
        }
        out <- t(apply(mat, 1, FUN.default, level = level))
    } else if (method == "percentile"){
        qs <- t(apply(object$boot[, parm, drop = FALSE], 2, quantile,
                      probs = c((1 - level)/2, 1 - (1 - level)/2)))
        mat <- cbind(coef(object, pars = "all")[parm], qs)
        FUN.percentile <- function(x){
            2*x[1] - c(x[3], x[2])
        }
        out <- t(apply(mat, 1, FUN.percentile))
    }
    percs <- c(100*(1 - level)/2, 100*(1 - (1 - level)/2))
    colnames(out) <- paste(round(percs, 2), "%")
    out
}
