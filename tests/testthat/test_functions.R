# helper to create temp output folder with automatic cleanup
create_temp_output <- function(name) {
  path <- file.path(tempdir(), name)
  dir.create(path, showWarnings = FALSE, recursive = TRUE)

  withr::defer(
    unlink(path, recursive = TRUE, force = TRUE),
    envir = parent.frame()
  )

  path
}

testthat::test_that("cheesecake() returns a list", {
  testthat::skip_if_not_installed("INLA")
  tmp <- create_temp_output("cheesecake")
  output <- cheesecake(df = toydata$admin, output_dir = tmp)
  testthat::expect_type(output, "list")
})

testthat::test_that("cheesepop() returns a list", {
  testthat::skip_if_not_installed("INLA")
  tmp <- create_temp_output("cheesepop")
  output <- cheesepop(df = toydata$admin, output_dir = tmp)
  testthat::expect_type(output, "list")
})

testthat::test_that("spices() returns a list", {
  testthat::skip_if_not_installed("INLA")
  tmp <- create_temp_output("spices")
  class_vars <- names(
    toydata$admin |> dplyr::select(dplyr::starts_with("age_"))
  )
  output <- spices(df = toydata$admin, output_dir = tmp, class = class_vars)
  testthat::expect_type(output, "list")
})

testthat::test_that("slices() returns a list", {
  testthat::skip_if_not_installed("INLA")
  tmp <- create_temp_output("slices")
  class_vars <- names(
    toydata$admin |> dplyr::select(dplyr::starts_with("age_"))
  )
  output <- slices(df = toydata$admin, output_dir = tmp, class = class_vars)
  testthat::expect_type(output, "list")
})

testthat::test_that("pyramid() returns a list", {
  testthat::skip_if_not_installed("INLA")
  tmp <- create_temp_output("pyramid")
  out1 <- cheesecake(df = toydata$admin, output_dir = tmp)
  out2 <- pyramid(out1$fem_age_pop, out1$male_age_pop)
  testthat::expect_type(out2, "list")
})
