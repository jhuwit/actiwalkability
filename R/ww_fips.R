#' Get Census Tract FIPS codes
#'
#' @param state 2-digit state FIPS code.
#' @param county 3-digit county FIPS code.
#' @param tract 6-digit tract FIPS code.
#' @param block 4-digit block FIPS code. If omitted or `NA`, tract-level codes
#' are returned.
#'
#' @return An 11-to-15 digit GEOID/FIPS code.
#' @export
#' @rdname acti_fips
#'
#' @examples
#' suppressWarnings(acti_fips15(24, 510, 60400))
#' acti_fips15(24, 510, 60400, block = 2002)
#' acti_fips12(24, 510, 60400, block = 2002)
acti_fips15 = function(state, county, tract, block = NA) {
  na_block <- is.na(block)
  if (any(na_block)) {
    warning("Some have NA block - giving those tract level")
  }

  fips15 <- sprintf("%02.0f%03.0f%06.0f", state, county, tract)
  fips15[!na_block] <- sprintf("%s%04.0f", fips15[!na_block], block[!na_block])
  fips15
}

#' @export
#' @rdname acti_fips
acti_fips12 = function(state, county, tract, block = NA) {
  fips15 <- acti_fips15(
    state = state,
    county = county,
    tract = tract,
    block = block
  )
  substr(fips15, 1, 12)
}
