% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/methods.r
\name{AIC.ascr}
\alias{AIC.ascr}
\title{Extract AIC from an ascr model object}
\usage{
\method{AIC}{ascr}(object, ..., k = 2)
}
\arguments{
\item{object}{A fitted model from \link[ascr]{fit.ascr}.}

\item{...}{Other parameters (for S3 generic compatibility).}

\item{k}{numeric, the \emph{penalty} per parameter to be used; the
    default \code{k = 2} is the classical AIC.}
}
\description{
Extracts the AIC from an ascr model object.
}
\details{
If the model is based on an acoustic survey where there are
multiple calls per individual, then AIC should not be used for
model selection. This function therefore returns NA in this case.
}

