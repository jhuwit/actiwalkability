#' Open the EPA Walkability Index layer
#'
#' @keywords internal
epa_arc = function() {
  url <- "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0"
  if (identical(tolower(Sys.getenv("ACTIWALKABILITY_DEBUG")), "true")) {
    return(structure(
      list(url = url, debug = TRUE),
      class = "actiwalkability_debug_arc"
    ))
  }
  acti_arc_open(url)
}

#' @keywords internal
acti_arc_open = function(url) {
  arcgislayers::arc_open(url)
}

#' @keywords internal
acti_arc_select = function(arc_walk, geometry, where, ...) {
  arcgislayers::arc_select(
    arc_walk,
    geometry = geometry,
    where = where,
    ...
  )
}

#' Get EPA Walkability Index
#'
#' @param geoid GEOID10 of the area of interest. This should be a 12 character
#' string. If `NULL`, then all GEOIDs are selected. This can be a lot of data,
#' so use with caution.
#' @param geometry Should geometry be returned? Passed to
#' [arcgislayers::arc_select()]
#' @param ... Additional arguments to pass to [arcgislayers::arc_select()]
#'
#' @return A `data.frame` of results.
#' @note See
#' \url{https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0}
#' @export
#'
#' @examplesIf rlang::is_installed("arcgislayers")
#' acti_epa_walkability(c("240054519002", "240054026041", "245102303002"))
acti_epa_walkability = function(geoid, geometry = TRUE, ...) {
  NatWalkInd = NULL
  rm(list = c("NatWalkInd"))
  rlang::check_installed("arcgislayers")

  where <- NULL
  if (!is.null(geoid)) {
    if (!all(nchar(geoid) == 12)) {
      warning("GEOID10 should be 12 characters long")
    }
    ids <- paste0("'", as.character(geoid), "'")
    where <- paste0("GEOID10 IN (", paste(ids, collapse = ", "), ")")
  }

  arc_walk <- epa_arc()
  res <- acti_arc_select(arc_walk, geometry = geometry, where = where, ...)

  if (nrow(res) > 0 && assertthat::has_name(res, "NatWalkInd")) {
    breaks <- c(1, 5.75, 10.5, 15.25, 20)
    res <- res %>%
      dplyr::mutate(
        cat_walk_index = cut(
          NatWalkInd,
          breaks = breaks,
          include.lowest = TRUE,
          right = TRUE
        )
      )
  }

  res
}
