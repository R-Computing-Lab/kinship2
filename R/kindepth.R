## Extracted from checks.Rnw

## Kindepth: helper function used throughout computes the depth of
# each subject in the pedigree.  
# For each subject this is defined as the maximal number of
# generations of ancestors: how far to the farthest founder.  
# This can be called with a pedigree object, or with the 
# full argument list.  In the former case we can simply skip a step

kindepth <- function(id, dad.id, mom.id, align=FALSE) {
    if (class(id)=='pedigree' || class(id)=='pedigreeList') {
        didx <- id$findex
        midx <- id$mindex
        n <- length(didx)
        } 
    else {
        n <- length(id)
        if (missing(dad.id) || length(dad.id) !=n)
            stop("Invalid father id")
        if (missing(mom.id) || length(mom.id) !=n)
            stop("Invalid mother id")
        midx <- match(mom.id, id, nomatch=0) # row number of my mom
        didx <- match(dad.id, id, nomatch=0) # row number of my dad
        }
    if (n==1) return (0)  # special case of a single subject 
    parents <- which(midx==0 & didx==0)  #founders

    depth <- rep(0,n)
    # At each iteration below, all children of the current "parents" are
    #    labeled with depth 'i', and become the parents of the next iteration
    for (i in 1:n) {
	child  <- match(midx, parents, nomatch=0) +
		  match(didx, parents, nomatch=0)

	if (all(child==0)) break
	if (i==n) 
	    stop("Impossible pedegree: someone is their own ancestor")

	parents <- which(child>0) #next generation of parents
	depth[parents] <- i
	}
    if (!align) return(depth)
    
    ## align
    ## Assume that subjects A and B marry, we have some ancestry information for
    ## both, and that A's ancestors go back 3 generations, B's for only two.  If we
    ## add +1 to the depth of B and all her ancestors, then A and B will be the same
    ## depth, and will plot on the same line.  Founders who marry in are also aligned.
    ## However, if an inbred pedigree, may not be a simple fix of this sort.

    ## The algorithm is 
    ## 1 First deal with founders. If a founder marries in multiple times at multiple
    ## deaths (animal pedigrees), given that subject the min(depth of spouses). These
    ## subjects cause trouble for the general algorithm below: the result would depend on the
    ## data order. 
    ## 2. Find any remaining mother-father pairs that are mismatched in depth.
    ##   Deal with them one at a time.
    ## 3.  The children's depth is max(father, mother) +1.  Call the
    ##   parent closest to the children ``good'' and the other ``bad''.
    ## 4. Chase up the good side, and get a list of all subjects connected
    ## to "good", including in-laws (spouse connections) and sibs that are
    ## at this level or above.  Call this agood (ancestors of good).
    ##We do not follow any connections at a depth lower than the 
    ##marriage in question, to get the highest marriages right.
    ##For the bad side, just get ancestors.
    ## 5. Avoid pedigree loops!  If the agood list contains anyone in abad,
    ## then don't try to fix the alignment, otherwise: Push abad down, then run the
    ## pushdown algorithm to repair any descendents --- you may have pulled down a
    ## grandparent but not the sibs of that grandparent.
    
    ##It may be possible to do better alignment when the pedigree has loops,
    ##but it is definitely beyond this program, perhaps in autohint one day.
    
    chaseup <- function(x, midx, didx) {
        new <- c(midx[x], didx[x])  # mother and father
        new <- new[new>0]
        while (length(new) >1) {
            x <- unique(c(x, new))
            new <- c(midx[new], didx[new])
            new <- new[new>0]
        }
        x
    } ## chaseup()
    	
    ## First deal with any parents who are founders
    ##  They all start with depth 0
    dads <- didx[midx>0 & didx>0]   # the father side of all spouse pairs
    moms <- midx[midx>0 & didx>0]
    founder <- (midx==0 & didx==0)
    if (any(founder[dads])) {
        drow <- which(founder[dads])  # which pairs
        id  <- unique(dads[drow])     # id
        depth[id] <- tapply(depth[moms[drow]], dads[drow], min)
        dads <- dads[-drow]
        moms <- moms[-drow]
    }
    if (any(founder[moms])) {
        mrow <- which(founder[moms])  # which pairs
        id  <- unique(moms[mrow])     # id
        depth[id] <- tapply(depth[dads[mrow]], moms[mrow], min)
        dads <- dads[-mrow]
        moms <- moms[-mrow]
    }
    
    ## Get rid of duplicate pairs, which occur for any spouse with
    ##  multiple offspring
    dups <- duplicated(dads + moms*n)
    if (any(dups)) {
        dads <- dads[!dups]
        moms <- moms[!dups]
    }
    
    npair<- length(dads)
    done <- rep(FALSE, npair)  #couples that are taken care of
    while (TRUE) {
        pairs.to.fix <- which((depth[dads] != depth[moms]) & !done)
        if (length(pairs.to.fix) ==0) break
        temp <- pmax(depth[dads], depth[moms])[pairs.to.fix]
        who <- min(pairs.to.fix[temp==min(temp)])  # the chosen couple
        
        good <- moms[who]; bad <- dads[who]
        if (depth[dads[who]] > depth[moms[who]]) {
            good <- dads[who]; bad <- moms[who]
        }
        abad  <- chaseup(bad,  midx, didx)
        if (length(abad) ==1 && sum(c(dads,moms)==bad)==1) {
                                        # simple case, a solitary marry-in
            depth[bad] <- depth[good]
        }
        else {
            agood <- chaseup(good, midx, didx)  #ancestors of the "good" side
            ## For spouse chasing, I need to exclude the given pair
            tdad <- dads[-who]
            tmom <- moms[-who]
            while (1) {
                ## spouses of any on agood list
                spouse <- c(tmom[!is.na(match(tdad, agood))],
                            tdad[!is.na(match(tmom, agood))])
                temp <- unique(c(agood, spouse))
                temp <- unique(chaseup(temp, midx, didx)) #parents
                kids <- (!is.na(match(midx, temp)) | !is.na(match(didx, temp)))
                temp <- unique(c(temp, (1:n)[kids & depth <= depth[good]]))
                if (length(temp) == length(agood)) break
                else agood <- temp
            }
            
            if (all(match(abad, agood, nomatch=0) ==0)) {
                ## shift it down
                depth[abad] <- depth[abad] + (depth[good] - depth[bad])
      
                ## Siblings may have had children: make sure all kids are
                ##   below their parents.  It's easiest to run through the
                ##   whole tree
                for (i in 0:n) {
                    parents <- which(depth==i)
                    child <- match(midx, parents, nomatch=0) +
                        match(didx, parents, nomatch=0)
                    if (all(child==0)) break
                    depth[child>0] <- pmax(i+1, depth[child>0])
                }
            }
        }
        ## Once a subject has been shifted, we don't allow them to instigate
        ##  yet another shift, possibly on another level
        done[dads==bad | moms==bad] <- TRUE
    } ## while(TRUE)
    if (all(depth>0)) stop("You found a bug in kindepth's alignment code!")
    depth    
}