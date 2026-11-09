epa_walkability_url = function() {
  "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0"
}

# The EPA layer's maxRecordCount; object IDs are requested in chunks this size.
epa_chunk_size = 1000L

#' Send a request to an ArcGIS REST endpoint
#'
#' Parameters are sent as a URL-encoded POST body so long `where` clauses
#' (many GEOIDs) do not overflow URL length limits.
#'
#' @param url Endpoint URL.
#' @param params Named list of query parameters.
#' @return The response body as a character string.
#' @keywords internal
#' @noRd
acti_arc_request = function(url, params = list()) {
  params <- params[!vapply(params, is.null, logical(1))]
  body <- paste(
    names(params),
    vapply(params, function(x) curl::curl_escape(as.character(x)), ""),
    sep = "=",
    collapse = "&"
  )
  h <- curl::new_handle()
  curl::handle_setopt(h, postfields = body)
  curl::handle_setheaders(
    h,
    "Content-Type" = "application/x-www-form-urlencoded"
  )
  res <- curl::curl_fetch_memory(url, handle = h)
  if (res$status_code >= 400) {
    stop("ArcGIS request failed with HTTP status ", res$status_code, ": ", url)
  }
  rawToChar(res$content)
}

# ArcGIS reports query errors as HTTP 200 with an `error` member.
arc_check_error = function(x) {
  if (is.list(x) && !is.null(x$error)) {
    details <- unlist(x$error$details)
    stop(
      "ArcGIS error ", x$error$code, ": ", x$error$message,
      if (length(details)) paste0(" (", paste(details, collapse = "; "), ")"),
      call. = FALSE
    )
  }
  x
}

acti_arc_json = function(url, params = list()) {
  params$f <- "json"
  txt <- acti_arc_request(url, params)
  arc_check_error(jsonlite::fromJSON(txt, simplifyVector = TRUE))
}

#' Get EPA Walkability Index layer metadata
#'
#' Requests the EPA Walkability Index ArcGIS layer description and returns its
#' metadata. This includes the available fields, layer extent, geometry type,
#' and service limits such as `maxRecordCount`.
#'
#' @return A list containing the ArcGIS layer metadata, with `fields` as a
#'   `data.frame` and the layer `url` added.
#' @note See
#' \url{https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0}
#' @export
#'
#' @examples
#' \dontrun{
#' metadata <- acti_epa_walkability_metadata()
#' metadata$fields
#' }
acti_epa_walkability_metadata = function() {
  url <- epa_walkability_url()
  meta <- acti_arc_json(url)
  meta$url <- url
  meta
}

arc_spatial_rel = function(predicate) {
  rel <- c(
    intersects = "esriSpatialRelIntersects",
    contains = "esriSpatialRelContains",
    crosses = "esriSpatialRelCrosses",
    envelope_intersects = "esriSpatialRelEnvelopeIntersects",
    index_intersects = "esriSpatialRelIndexIntersects",
    overlaps = "esriSpatialRelOverlaps",
    touches = "esriSpatialRelTouches",
    within = "esriSpatialRelWithin"
  )
  predicate <- match.arg(tolower(predicate), names(rel))
  unname(rel[predicate])
}

#' Convert an sf/sfc/sfg/bbox object to ArcGIS query geometry parameters
#' @keywords internal
#' @noRd
arc_filter_geometry = function(filter_geom, predicate = "intersects") {
  rlang::check_installed("sf", reason = "to use `filter_geom`.")
  to_wgs84 = function(x) {
    crs <- sf::st_crs(x)
    if (!is.na(crs) && !isTRUE(crs == sf::st_crs(4326))) {
      x <- sf::st_transform(x, 4326)
    }
    x
  }
  sr <- list(wkid = 4326L)
  if (inherits(filter_geom, "bbox")) {
    filter_geom <- to_wgs84(sf::st_as_sfc(filter_geom))
    bb <- sf::st_bbox(filter_geom)
    geom <- list(
      xmin = bb[["xmin"]], ymin = bb[["ymin"]],
      xmax = bb[["xmax"]], ymax = bb[["ymax"]],
      spatialReference = sr
    )
    type <- "esriGeometryEnvelope"
  } else {
    if (inherits(filter_geom, "sfg")) {
      filter_geom <- sf::st_sfc(filter_geom, crs = 4326)
    }
    g <- to_wgs84(sf::st_geometry(filter_geom))
    g <- sf::st_zm(sf::st_union(g))
    gtype <- as.character(sf::st_geometry_type(g))
    coords_of = function(x) lapply(x, function(m) unclass(m)[, 1:2, drop = FALSE])
    if (gtype %in% c("POLYGON", "MULTIPOLYGON")) {
      polys <- sf::st_cast(g, "POLYGON")
      geom <- list(rings = unlist(lapply(polys, coords_of), recursive = FALSE),
                   spatialReference = sr)
      type <- "esriGeometryPolygon"
    } else if (gtype %in% c("LINESTRING", "MULTILINESTRING")) {
      lines <- sf::st_cast(g, "LINESTRING")
      geom <- list(paths = lapply(lines, function(m) unclass(m)[, 1:2, drop = FALSE]),
                   spatialReference = sr)
      type <- "esriGeometryPolyline"
    } else if (gtype %in% c("POINT", "MULTIPOINT")) {
      xy <- sf::st_coordinates(g)[, 1:2, drop = FALSE]
      if (nrow(xy) == 1) {
        geom <- list(x = xy[1, 1], y = xy[1, 2], spatialReference = sr)
        type <- "esriGeometryPoint"
      } else {
        geom <- list(points = unname(xy), spatialReference = sr)
        type <- "esriGeometryMultipoint"
      }
    } else {
      stop("Unsupported `filter_geom` geometry type: ", gtype)
    }
  }
  list(
    geometry = as.character(jsonlite::toJSON(geom, auto_unbox = TRUE, digits = NA)),
    geometryType = type,
    inSR = 4326L,
    spatialRel = arc_spatial_rel(predicate)
  )
}

# Coerce attribute columns using the ArcGIS field types (numbers as double,
# dates from epoch milliseconds), so results are typed consistently even when
# a chunk is all-NULL for a column.
arc_type_columns = function(df, fields) {
  if (is.null(fields) || !is.data.frame(fields)) return(df)
  for (i in seq_len(nrow(fields))) {
    nm <- fields$name[i]
    if (!nm %in% names(df)) next
    df[[nm]] <- switch(
      fields$type[i],
      esriFieldTypeString = ,
      esriFieldTypeGUID = ,
      esriFieldTypeGlobalID = as.character(df[[nm]]),
      esriFieldTypeDouble = ,
      esriFieldTypeSingle = ,
      esriFieldTypeInteger = ,
      esriFieldTypeSmallInteger = ,
      esriFieldTypeBigInteger = ,
      esriFieldTypeOID = as.double(df[[nm]]),
      esriFieldTypeDate = as.POSIXct(as.double(df[[nm]]) / 1000,
                                     origin = "1970-01-01", tz = "UTC"),
      df[[nm]]
    )
  }
  df
}

arc_empty_frame = function(fields) {
  if (is.null(fields) || !is.data.frame(fields) || nrow(fields) == 0) {
    return(dplyr::tibble())
  }
  fields <- fields[fields$type != "esriFieldTypeGeometry", , drop = FALSE]
  df <- as.data.frame(
    stats::setNames(rep(list(logical(0)), nrow(fields)), fields$name),
    stringsAsFactors = FALSE
  )
  dplyr::as_tibble(arc_type_columns(df, fields))
}

arc_query_attributes = function(url, params, object_ids) {
  chunks <- split(object_ids, ceiling(seq_along(object_ids) / epa_chunk_size))
  out <- lapply(chunks, function(ids) {
    p <- params
    p$objectIds <- paste(ids, collapse = ",")
    p$returnGeometry <- "false"
    res <- acti_arc_json(url, p)
    attrs <- res$features$attributes
    if (is.null(attrs)) return(arc_empty_frame(res$fields))
    dplyr::as_tibble(arc_type_columns(attrs, res$fields))
  })
  dplyr::bind_rows(out)
}

arc_query_geojson = function(url, params, object_ids) {
  chunks <- split(object_ids, ceiling(seq_along(object_ids) / epa_chunk_size))
  out <- lapply(chunks, function(ids) {
    p <- params
    p$objectIds <- paste(ids, collapse = ",")
    p$returnGeometry <- "true"
    # Keep the layer's native Web Mercator CRS, as arcgislayers returned.
    p$outSR <- 3857L
    p$f <- "geojson"
    txt <- acti_arc_request(url, p)
    if (grepl('^\\s*\\{\\s*"error"', txt)) {
      arc_check_error(jsonlite::fromJSON(txt, simplifyVector = TRUE))
    }
    x <- sf::st_read(txt, quiet = TRUE)
    # GDAL reads whole numbers as integer; use double as for attribute queries
    is_int <- vapply(sf::st_drop_geometry(x), is.integer, logical(1))
    for (nm in names(is_int)[is_int]) x[[nm]] <- as.double(x[[nm]])
    x
  })
  res <- do.call(rbind, unname(out))
  sf::st_crs(res) <- 3857
  res
}

#' Get EPA Walkability Index
#'
#' Queries the EPA National Walkability Index ArcGIS layer directly through its
#' REST API.  Results are requested in chunks of the service's
#' `maxRecordCount`, so large selections are returned in full.
#'
#' @param geoid GEOID10 of the area of interest. This should be a 12 character
#' string. If `NULL`, then all GEOIDs are selected (subject to `filter_geom`).
#' This can be a lot of data, so use with caution.
#' @param geometry Should block-group polygons be returned?  If `TRUE`, the
#' result is an `sf` object in Web Mercator (EPSG:3857), which requires the
#' \pkg{sf} package.  If `FALSE` (default), a tibble of attributes.
#' @param fields Character vector of fields to return.  `NULL` (default) returns
#' all fields.  See `acti_epa_walkability_metadata()$fields`.
#' @param filter_geom Optional spatial filter: an `sf`, `sfc`, `sfg`, or `bbox`
#' object (requires \pkg{sf}).  Multiple features are unioned.
#' @param predicate Spatial relationship between the layer and `filter_geom`:
#' one of `"intersects"`, `"contains"`, `"crosses"`, `"envelope_intersects"`,
#' `"index_intersects"`, `"overlaps"`, `"touches"`, or `"within"`.
#' @param n_max Maximum number of records to return.
#' @param ... Additional named ArcGIS query parameters passed to the layer's
#' `query` endpoint (see the ArcGIS REST API "Query (Map Service/Layer)"
#' documentation).
#'
#' @return A tibble (or an `sf` object if `geometry = TRUE`) with a
#'   `cat_walk_index` factor added when `NatWalkInd` is returned.
#' @note See
#' \url{https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0}
#' @export
#'
#' @examples
#' \donttest{
#' if (curl::has_internet()) {
#'   acti_epa_walkability(c("240054519002", "240054026041", "245102303002"))
#' }
#' }
acti_epa_walkability = function(geoid,
                                geometry = FALSE,
                                fields = NULL,
                                filter_geom = NULL,
                                predicate = "intersects",
                                n_max = Inf,
                                ...) {
  NatWalkInd = NULL
  rm(list = c("NatWalkInd"))
  assertthat::assert_that(
    assertthat::is.flag(geometry), !is.na(geometry),
    is.numeric(n_max), length(n_max) == 1, !is.na(n_max), n_max >= 0
  )
  if (geometry) {
    rlang::check_installed("sf", reason = "to return geometry.")
  }
  extra <- list(...)
  if (length(extra) && (is.null(names(extra)) || any(names(extra) == ""))) {
    stop("Arguments in `...` must be named ArcGIS query parameters.")
  }

  where <- "1=1"
  if (!is.null(geoid)) {
    if (!all(nchar(geoid) == 12)) {
      warning("GEOID10 should be 12 characters long")
    }
    ids <- paste0("'", gsub("'", "''", as.character(geoid)), "'")
    where <- paste0("GEOID10 IN (", paste(ids, collapse = ", "), ")")
  }

  url <- paste0(epa_walkability_url(), "/query")
  params <- c(list(where = where), extra)
  if (!is.null(filter_geom)) {
    params <- c(params, arc_filter_geometry(filter_geom, predicate))
  }

  id_res <- acti_arc_json(url, c(params, list(returnIdsOnly = "true")))
  object_ids <- sort(unlist(id_res$objectIds))
  if (is.finite(n_max)) {
    object_ids <- utils::head(object_ids, n_max)
  }

  params$outFields <- if (is.null(fields)) "*" else paste(fields, collapse = ",")
  params$where <- NULL
  params[c("geometry", "geometryType", "inSR", "spatialRel")] <- NULL

  if (length(object_ids) == 0) {
    empty <- acti_arc_json(
      url,
      list(where = "1=0", outFields = params$outFields, returnGeometry = "false")
    )
    res <- arc_empty_frame(empty$fields)
    if (geometry) {
      res <- sf::st_sf(res, geometry = sf::st_sfc(crs = 3857))
    }
  } else if (geometry) {
    res <- arc_query_geojson(url, params, object_ids)
  } else {
    res <- arc_query_attributes(url, params, object_ids)
  }

  if (length(object_ids) > 0 && nrow(res) != length(object_ids)) {
    warning("Requested ", length(object_ids), " records but received ",
            nrow(res), ".")
  }

  if (nrow(res) > 0 && assertthat::has_name(res, "NatWalkInd")) {
    breaks <- c(1, 5.75, 10.5, 15.25, 20)
    res <- res |>
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
