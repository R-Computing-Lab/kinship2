% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/alignped2.R
\name{alignped2}
\alias{alignped2}
\title{Second routine alignment}
\usage{
alignped2(x, dad, mom, level, horder, packed, spouselist)
}
\arguments{
\item{spouselist}{}
}
\value{
A set of matrices along with the spouselist matrix.
The latter has marriages removed as they are processed.
}
\description{
This is the second of the four co-routines.
}
\details{
This routine takes a collection of siblings, grows the tree for each,
and appends them side by side into a single tree.
The input arguments are the same as those to \code{alignped1} with the
exception that \code{[[x]]} will be a vector. This routine does nothing
to the spouselist matrix, but needs to pass it down the tree and back
since one of the routines called by \code{alignped2} might change the matrix.

The code below has one non-obvious special case. Suppose that two sibs marry.
When the first sib is processed by \code{alignped1} then both partners
(and any children) will be added to the rval structure below.
When the second sib is processed they will come back as a 1 element tree
(the marriage will no longer be on the spouselist), which should be added
onto rval. The rule thus is to not add any 1 element tree whose value
(which must be \code{x[i]}) is already in the rval structure for this level.
}
\examples{
data(sample.ped)
ped <- with(sample.ped, pedigree(id, father, mother, sex, affected))
align.pedigree(ped)

}
\seealso{
\code{\link{plot.pedigree}}, \code{\link{autohint}}
}
\keyword{dplot}
