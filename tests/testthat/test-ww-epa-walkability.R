test_that("epa_arc uses the debug stub when requested", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")

  result <- epa_arc()

  expect_s3_class(result, "actiwalkability_debug_arc")
  expect_equal(
    result$url,
    "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0"
  )
})

test_that("acti_arc_open delegates to arcgislayers::arc_open", {
  sentinel <- structure(list(url = "ok"), class = "fake_arc")

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_open = function(url) {
      expect_equal(url, "https://example.org/layer")
      sentinel
    }
  )

  result <- acti_arc_open("https://example.org/layer")

  expect_identical(result, sentinel)
})

test_that("acti_arc_select delegates to arcgislayers::arc_select", {
  sentinel <- dplyr::tibble(value = 1)
  fake_arc <- structure(list(), class = "fake_arc")

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      expect_true(geometry)
      expect_equal(where, "GEOID10 IN ('123')")
      expect_equal(list(...), list())
      sentinel
    }
  )

  result <- acti_arc_select(
    fake_arc,
    geometry = TRUE,
    where = "GEOID10 IN ('123')"
  )

  expect_identical(result, sentinel)
})

test_that("acti_epa_walkability builds the EPA query", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")
  fake_arc <- epa_arc()
  fake_result <- dplyr::tibble(NatWalkInd = c(2, 8))

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      expect_true(geometry)
      expect_equal(where, "GEOID10 IN ('240054519002', '240054026041')")
      expect_equal(list(...), list())
      fake_result
    }
  )

  result <- acti_epa_walkability(c("240054519002", "240054026041"))

  expect_true("cat_walk_index" %in% names(result))
  expect_equal(as.character(result$cat_walk_index), c("[1,5.75]", "(5.75,10.5]"))
})

test_that("acti_epa_walkability accepts all GEOIDs when geoid is NULL", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")
  fake_arc <- epa_arc()

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      expect_true(geometry)
      expect_null(where)
      dplyr::tibble()
    }
  )

  result <- acti_epa_walkability(NULL)

  expect_equal(nrow(result), 0L)
})

test_that("acti_epa_walkability leaves results unchanged when NatWalkInd is absent", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")
  fake_arc <- epa_arc()
  fake_result <- dplyr::tibble(other = 1)

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      expect_true(geometry)
      expect_null(where)
      fake_result
    }
  )

  result <- acti_epa_walkability(NULL)

  expect_false("cat_walk_index" %in% names(result))
  expect_identical(result, fake_result)
})

test_that("acti_epa_walkability warns on non-12 character geoid", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")
  fake_arc <- epa_arc()

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      dplyr::tibble()
    }
  )

  expect_warning(
    acti_epa_walkability("123"),
    "GEOID10 should be 12 characters long"
  )
})

test_that("acti_epa_walkability surfaces open failures", {
  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_open = function(...) stop("no internet")
  )

  expect_error(
    epa_arc(),
    "no internet"
  )
})

test_that("acti_epa_walkability surfaces select failures", {
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "true")

  testthat::local_mocked_bindings(
    .package = "arcgislayers",
    arc_select = function(...) stop("http 500")
  )

  expect_error(
    acti_epa_walkability("240054519002"),
    "http 500"
  )
})

test_that("acti_epa_walkability works against the live EPA service", {
  if (requireNamespace("curl", quietly = TRUE) && !curl::has_internet()) {
    testthat::skip("No internet")
  }
  testthat::skip_if_not_installed("arcgislayers")
  withr::local_envvar(ACTIWALKABILITY_DEBUG = "")

  result <- acti_epa_walkability(
    "240054519002",
    geometry = FALSE,
    n_max = 1
  )

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0L)
  expect_true("NatWalkInd" %in% names(result))
})
