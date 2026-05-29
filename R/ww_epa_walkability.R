#' Open the EPA Walkability Index layer
#'
#' @keywords internal
epa_arc = function(arc_open_fn = acti_arc_open) {
  url <- "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0"
  arc_open_fn(url)
}

#' @keywords internal
acti_arc_open = function(url, arc_open_fn = arcgislayers::arc_open) {
  arc_open_fn(url)
}

#' @keywords internal
acti_arc_select = function(
  arc_walk,
  geometry,
  where,
  arc_select_fn = arcgislayers::arc_select,
  ...
) {
  arc_select_fn(
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

  res <- tryCatch({
    arc_walk <- epa_arc()
    acti_arc_select(arc_walk, geometry = geometry, where = where, ...)
  }, error = function(e) {
    warning(
      "EPA Walkability query failed; returning empty result: ",
      conditionMessage(e),
      call. = FALSE
    )
    dplyr::tibble()
  })

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
