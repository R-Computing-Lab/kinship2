# $Id: makefamid.s,v 1.7 2003/01/07 15:47:08 therneau Exp

#' Get family id
#'
#' @description
#' Construct a family id from pedigree information
#'
#' @details
#' Create a vector of length n, giving the family "tree" number of each
#' subject.  If the pedigree is totally connected, then everyone will end up in
#' tree 1, otherwise the tree numbers represent the disconnected subfamilies.
#' Singleton subjects give a zero for family number.
#'
#' This command is depricated.  The kinship command now can be applied directly
#' to pedigreeList objects.
#'
#' @param id Identifier for each subject in the set of pedigrees
#' @param father.id Identifier for the father.  This will be 0 or "" for a
#' founder.
#' @param mother.id Identifier for the mother.
#'
#' @return An integer vector giving family groupings
#'
#' @author Terry Therneau
#' @seealso \code{\link{makekinship}}
#' @keywords genetics
#' @export makefamid
makefamid <- function(id, father.id, mother.id) {
  n <- length(id)
  mid <- c(match(mother.id, id, nomatch = n + 1), n + 1)
  did <- c(match(father.id, id, nomatch = n + 1), n + 1)
  mid2 <- sort(unique(mid))
  did2 <- sort(unique(did))
  famid <- 1:(n + 1)
  # The key idea of the algorithm:
  #  1. iteratively set the family id of parent/child sets to the
  #       minimum value of the set
  #  2. add a subject "n+1", who is the parent of all orphans, and
  #       also of himself, to make the father/mother/child vectors
  #       all be the same length

  # Run the depth routine to check for impossible parentage loops,
  #  which would lead to infinite iterations.
  # And even then, give it an upper limit of n iterations (it should
  #   never even come close to this).  You might think it would finish in
  #   max(depth) iterations, but assume 2 families of depth 3 who intermarry
  #   at the last generation: the final id propogates down one tree and
  #   then up the other.  Chains can take even longer (child of A marries
  #   child of B, second child of B marries child of C, second child of C
  #   marries child of D, ...).  However, at each iteration the final number
  #   must get propogated to at least one child or at least 2 parents, giving
  #   a limit of n-1
  temp <- kindepth(id, father.id, mother.id)
  for (i in 1:n) {
    # set children = min(self, parents)
    newid <- pmin(famid, famid[mid], famid[did])
    # mom = min(mon, children)
    # dad = min(dad, children)
    newid[mid2] <- pmin(newid[mid2], tapply(newid, mid, min))
    newid[n + 1] <- n + 1 # preserve the "no parent" code
    newid[did2] <- pmin(newid[did2], tapply(newid, did, min))
    newid[n + 1] <- n + 1 # preserve the "no parent" code

    if (all(newid == famid)) {
      break
    } else if (i < n) famid <- newid
  }

  if (all(newid == famid)) {
    # renumber the results : family 0 for uniques, else small integers
    famid <- famid[1:n] # toss the "n+1" obs
    xx <- table(famid)
    if (any(xx == 1)) {
      singles <- as.integer(names(xx[xx == 1])) # famid of singletons
      famid[!is.na(match(famid, singles))] <- 0 # set singletons to 0
      match(famid, sort(unique(famid))) - 1 # renumber
    } else {
      match(famid, sort(unique(famid)))
    } # renumber, no zeros
  } else {
    stop("Bug in routine: seem to have found an infinite loop")
  }
}
