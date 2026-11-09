test_that("acti_epa_walkability builds the GEOID query and types columns", {
  srv <- fake_arc_server(c(3L, 1L, 2L))
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)

  res <- acti_epa_walkability(c("240054519002", "240054026041"))

  calls <- srv$env$calls
  expect_length(calls, 2)
  expect_match(calls[[1]]$url, "WalkabilityIndex/MapServer/0/query$")
  expect_equal(
    calls[[1]]$where,
    "GEOID10 IN ('240054519002', '240054026041')"
  )
  expect_equal(calls[[1]]$returnIdsOnly, "true")
  expect_equal(calls[[2]]$objectIds, "1,2,3")
  expect_equal(calls[[2]]$outFields, "*")
  expect_equal(calls[[2]]$returnGeometry, "false")
  expect_equal(calls[[2]]$f, "json")
  expect_null(calls[[2]]$where)

  expect_s3_class(res, "tbl_df")
  expect_equal(res$OBJECTID, c(1, 2, 3))
  expect_type(res$TotPop, "double")
  expect_type(res$GEOID10, "character")
  expect_s3_class(res$cat_walk_index, "factor")
  expect_equal(
    as.character(res$cat_walk_index),
    as.character(cut(res$NatWalkInd, c(1, 5.75, 10.5, 15.25, 20),
                     include.lowest = TRUE))
  )
})

test_that("acti_epa_walkability requests records in maxRecordCount chunks", {
  srv <- fake_arc_server(seq_len(2500))
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)

  res <- acti_epa_walkability(NULL, fields = c("GEOID10", "NatWalkInd"))

  calls <- srv$env$calls
  expect_equal(calls[[1]]$where, "1=1")
  data_calls <- calls[-1]
  expect_length(data_calls, 3)
  expect_equal(
    vapply(data_calls, function(x) length(strsplit(x$objectIds, ",")[[1]]), 1L),
    c(1000L, 1000L, 500L)
  )
  expect_equal(data_calls[[1]]$outFields, "GEOID10,NatWalkInd")
  expect_equal(nrow(res), 2500)
})

test_that("acti_epa_walkability respects n_max", {
  srv <- fake_arc_server(seq_len(50))
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)

  res <- acti_epa_walkability(NULL, n_max = 5)
  expect_equal(nrow(res), 5)
  expect_equal(srv$env$calls[[2]]$objectIds, "1,2,3,4,5")
})

test_that("acti_epa_walkability returns a typed empty tibble with no matches", {
  srv <- fake_arc_server(integer(0))
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)

  res <- acti_epa_walkability("000000000000")
  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 0)
  expect_equal(names(res), c("OBJECTID", "GEOID10", "NatWalkInd", "TotPop"))
  expect_type(res$GEOID10, "character")
  expect_type(res$NatWalkInd, "double")
})

test_that("acti_epa_walkability warns on non-12 character geoid", {
  srv <- fake_arc_server(1L)
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)
  expect_warning(acti_epa_walkability("123"), "12 characters")
})

test_that("acti_epa_walkability escapes quotes in geoid", {
  srv <- fake_arc_server(1L)
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)
  suppressWarnings(acti_epa_walkability("1' OR '1'='1"))
  expect_equal(srv$env$calls[[1]]$where, "GEOID10 IN ('1'' OR ''1''=''1')")
})

test_that("acti_epa_walkability passes named extra query parameters", {
  srv <- fake_arc_server(1L)
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)
  acti_epa_walkability("240054519002", gdbVersion = "v1")
  expect_equal(srv$env$calls[[1]]$gdbVersion, "v1")
  expect_equal(srv$env$calls[[2]]$gdbVersion, "v1")
  expect_error(
    acti_epa_walkability("240054519002", FALSE, NULL, NULL, "intersects", Inf,
                         "oops"),
    "named"
  )
  expect_error(acti_epa_walkability("240054519002", geometry = "yes"))
})

test_that("ArcGIS errors and HTTP failures surface", {
  testthat::local_mocked_bindings(
    acti_arc_request = function(url, params = list()) {
      '{"error":{"code":400,"message":"Failed to execute query.","details":["bad field"]}}'
    }
  )
  expect_error(
    acti_epa_walkability("240054519002"),
    "ArcGIS error 400: Failed to execute query. \\(bad field\\)"
  )

  testthat::local_mocked_bindings(
    acti_arc_request = function(url, params = list()) stop("http 500")
  )
  expect_error(acti_epa_walkability("240054519002"), "http 500")
})

test_that("acti_arc_request URL-encodes a POST body and checks status", {
  seen <- new.env()
  testthat::local_mocked_bindings(
    .package = "curl",
    curl_fetch_memory = function(url, handle) {
      seen$url <- url
      list(status_code = 200L, content = charToRaw('{"ok":true}'))
    }
  )
  out <- acti_arc_request("https://example.org/q",
                          list(where = "a = 'b'", skip = NULL, f = "json"))
  expect_equal(out, '{"ok":true}')
  expect_equal(seen$url, "https://example.org/q")

  testthat::local_mocked_bindings(
    .package = "curl",
    curl_fetch_memory = function(url, handle) {
      list(status_code = 503L, content = raw(0))
    }
  )
  expect_error(acti_arc_request("https://example.org/q"), "HTTP status 503")
})

test_that("arc_spatial_rel maps predicates", {
  expect_equal(arc_spatial_rel("intersects"), "esriSpatialRelIntersects")
  expect_equal(arc_spatial_rel("Within"), "esriSpatialRelWithin")
  expect_error(arc_spatial_rel("near"))
})

test_that("arc_filter_geometry converts sf inputs to ArcGIS geometry", {
  testthat::skip_if_not_installed("sf")
  bb <- sf::st_bbox(c(xmin = -76.7, ymin = 39.2, xmax = -76.5, ymax = 39.4),
                    crs = 4326)

  env <- arc_filter_geometry(bb)
  expect_equal(env$geometryType, "esriGeometryEnvelope")
  expect_equal(env$spatialRel, "esriSpatialRelIntersects")
  g <- jsonlite::fromJSON(env$geometry)
  expect_equal(unlist(g[c("xmin", "ymin", "xmax", "ymax")]),
               c(xmin = -76.7, ymin = 39.2, xmax = -76.5, ymax = 39.4))

  poly <- arc_filter_geometry(sf::st_as_sfc(bb), predicate = "within")
  expect_equal(poly$geometryType, "esriGeometryPolygon")
  expect_equal(poly$spatialRel, "esriSpatialRelWithin")
  rings <- jsonlite::fromJSON(poly$geometry, simplifyVector = FALSE)$rings
  expect_length(rings, 1)
  expect_length(rings[[1]], 5)

  # projected input is transformed to WGS84
  merc <- sf::st_transform(sf::st_as_sfc(bb), 3857)
  pm <- jsonlite::fromJSON(arc_filter_geometry(merc)$geometry)
  expect_true(all(abs(pm$rings[, , 1]) <= 180))

  pt <- arc_filter_geometry(sf::st_point(c(-76.6, 39.3)))
  expect_equal(pt$geometryType, "esriGeometryPoint")
})

test_that("filter_geom is sent with the ID query only", {
  testthat::skip_if_not_installed("sf")
  srv <- fake_arc_server(1L)
  testthat::local_mocked_bindings(acti_arc_request = srv$fn)
  bb <- sf::st_bbox(c(xmin = -76.7, ymin = 39.2, xmax = -76.5, ymax = 39.4),
                    crs = 4326)
  acti_epa_walkability(NULL, filter_geom = bb)
  expect_equal(srv$env$calls[[1]]$geometryType, "esriGeometryEnvelope")
  expect_equal(srv$env$calls[[1]]$inSR, 4326L)
  expect_null(srv$env$calls[[2]]$geometry)
})

test_that("geometry = TRUE returns sf in EPSG:3857", {
  testthat::skip_if_not_installed("sf")
  testthat::local_mocked_bindings(
    acti_arc_request = function(url, params = list()) {
      if (identical(params$returnIdsOnly, "true")) {
        return('{"objectIds":[1]}')
      }
      expect_equal(params$f, "geojson")
      expect_equal(params$outSR, 3857L)
      paste0(
        '{"type":"FeatureCollection","crs":{"type":"name","properties":',
        '{"name":"EPSG:3857"}},"features":[{"type":"Feature","geometry":',
        '{"type":"Polygon","coordinates":[[[0,0],[0,10],[10,10],[10,0],[0,0]]]},',
        '"properties":{"OBJECTID":1,"GEOID10":"240054519002","NatWalkInd":4.5}}]}'
      )
    }
  )
  res <- acti_epa_walkability("240054519002", geometry = TRUE)
  expect_s3_class(res, "sf")
  expect_equal(sf::st_crs(res), sf::st_crs(3857))
  expect_type(res$OBJECTID, "double")
  expect_equal(as.character(res$cat_walk_index), "[1,5.75]")
  expect_equal(as.numeric(sf::st_area(res)), 100)
})

test_that("acti_epa_walkability works against the live EPA service", {
  testthat::skip_on_cran()
  testthat::skip_if_offline("geodata.epa.gov")

  result <- acti_epa_walkability(
    c("240054519002", "240054026041"),
    fields = c("GEOID10", "NatWalkInd")
  )

  expect_s3_class(result, "tbl_df")
  expect_equal(sort(result$GEOID10), c("240054026041", "240054519002"))
  expect_type(result$NatWalkInd, "double")
})
