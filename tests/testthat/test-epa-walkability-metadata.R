test_that("acti_epa_walkability_metadata returns the EPA layer metadata", {
  testthat::skip_if_not_installed("arcgislayers")
  sentinel <- structure(
    list(fields = list(list(name = "GEOID10"))),
    class = "FeatureLayer"
  )

  testthat::local_mocked_bindings(
    .package = "actiwalkability",
    epa_arc = function() sentinel
  )

  result <- acti_epa_walkability_metadata()

  expect_identical(result, sentinel)
})
