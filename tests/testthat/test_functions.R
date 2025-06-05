library(testthat)        # load testthat package
library(jollofR)       # load our package
library(dplyr)

# Test that the cheesecake function runs well and outputs a list
test_that("cheesecake() returns a list", {
  output_table <- cheesecake(df = toydata, output_dir = tempdir())
  expect_type(output_table, "list")
})


# Test that the cheesepop function runs well and outputs a list
test_that("cheesepop() returns a list", {
  output_table <- cheesepop(df = toydata, output_dir = tempdir())
  expect_type(output_table, "list")
})



# Test that the scissors function runs well and outputs a list
test_that("spices() returns a list", {
  class <- names(toydata %>% dplyr::select(starts_with("age_")))
  output_table <- spices(df = toydata, output_dir = tempdir(), class)
  expect_type(output_table, "list")
})

# Test that the slices function runs well and outputs a list
test_that("slices() returns a list", {
  class <- names(toydata %>% dplyr::select(starts_with("age_")))
  output_table <- slices(df = toydata, output_dir = tempdir(), class)
  expect_type(output_table, "list")
})


# Test that the pyramid function runs well and outputs a list
test_that("pyramid() returns a list", {
  output_table <- cheesecake(df = toydata, output_dir = tempdir())
  output_table2 <- pyramid(output_table$fem_age_pop, output_table$male_age_pop)
  expect_type(output_table2, "list")
})
