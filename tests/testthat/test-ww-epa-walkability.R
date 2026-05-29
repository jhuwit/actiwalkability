test_that("epa_arc delegates to the opener", {
  sentinel <- structure(list(url = "ok"), class = "fake_arc")

  result <- epa_arc(arc_open_fn = function(url) {
    expect_equal(
      url,
      "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0"
    )
    sentinel
  })

  expect_identical(result, sentinel)
})

test_that("acti_arc_open delegates to arcgislayers::arc_open replacement", {
  sentinel <- structure(list(url = "ok"), class = "fake_arc")

  result <- acti_arc_open("https://example.org/layer", arc_open_fn = function(url) {
    expect_equal(url, "https://example.org/layer")
    sentinel
  })

  expect_identical(result, sentinel)
})

test_that("acti_arc_select delegates to arcgislayers::arc_select replacement", {
  sentinel <- dplyr::tibble(value = 1)
  fake_arc <- structure(list(), class = "fake_arc")

  result <- acti_arc_select(
    fake_arc,
    geometry = TRUE,
    where = "GEOID10 IN ('123')",
    arc_select_fn = function(arc_walk, geometry, where, ...) {
      expect_identical(arc_walk, fake_arc)
      expect_true(geometry)
      expect_equal(where, "GEOID10 IN ('123')")
      expect_equal(list(...), list())
      sentinel
    }
  )

  expect_identical(result, sentinel)
})

test_that("acti_epa_walkability builds the EPA query", {
  fake_arc <- structure(list(), class = "fake_arc")
  fake_result <- dplyr::tibble(NatWalkInd = c(2, 8))

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() fake_arc,
    acti_arc_select = function(arc_walk, geometry, where, ...) {
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
  fake_arc <- structure(list(), class = "fake_arc")

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() fake_arc,
    acti_arc_select = function(arc_walk, geometry, where, ...) {
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
  fake_arc <- structure(list(), class = "fake_arc")
  fake_result <- dplyr::tibble(other = 1)

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() fake_arc,
    acti_arc_select = function(arc_walk, geometry, where, ...) {
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
  fake_arc <- structure(list(), class = "fake_arc")

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() fake_arc,
    acti_arc_select = function(arc_walk, geometry, where, ...) {
      dplyr::tibble()
    }
  )

  expect_warning(
    acti_epa_walkability("123"),
    "GEOID10 should be 12 characters long"
  )
})

test_that("acti_epa_walkability returns empty results when EPA open fails", {
  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() stop("no internet"),
    acti_arc_select = function(...) {
      stop("should not be called")
    }
  )

  expect_warning(
    result <- acti_epa_walkability("240054519002"),
    "EPA Walkability query failed; returning empty result: no internet"
  )

  expect_equal(nrow(result), 0L)
  expect_equal(ncol(result), 0L)
})

test_that("acti_epa_walkability returns empty results when EPA select fails", {
  fake_arc <- structure(list(), class = "fake_arc")

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() fake_arc,
    acti_arc_select = function(...) stop("http 500")
  )

  expect_warning(
    result <- acti_epa_walkability("240054519002"),
    "EPA Walkability query failed; returning empty result: http 500"
  )

  expect_equal(nrow(result), 0L)
  expect_equal(ncol(result), 0L)
})
