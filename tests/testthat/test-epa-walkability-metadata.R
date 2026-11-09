test_that("acti_epa_walkability_metadata returns the EPA layer metadata", {
  testthat::local_mocked_bindings(
    acti_arc_request = function(url, params = list()) {
      expect_equal(params$f, "json")
      '{"name":"NationalWalkabilityIndex","maxRecordCount":1000,
        "fields":[{"name":"GEOID10","type":"esriFieldTypeString"}]}'
    }
  )

  result <- acti_epa_walkability_metadata()

  expect_equal(result$maxRecordCount, 1000)
  expect_s3_class(result$fields, "data.frame")
  expect_equal(result$fields$name, "GEOID10")
  expect_match(result$url, "WalkabilityIndex/MapServer/0$")
})
