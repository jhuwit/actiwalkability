test_that("acti_fips15 creates tract and block codes", {
  expect_equal(suppressWarnings(acti_fips15(24, 510, 60400)), "24510060400")
  expect_equal(acti_fips15(24, 510, 60400, block = 2002), "245100604002002")
})

test_that("acti_fips12 truncates to 12 characters", {
  expect_equal(acti_fips12(24, 510, 60400, block = 2002), "245100604002")
})

test_that("acti_fips15 warns when block is missing", {
  expect_warning(
    expect_equal(acti_fips15(24, 510, 60400, block = NA), "24510060400"),
    "NA block"
  )
})
