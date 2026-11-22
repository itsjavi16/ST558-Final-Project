library(plumber)
library(tidyverse)
library(tidymodels)
library(janitor)

#  Read in and clean the data (same steps as index.qmd) 
housing <- read_csv("data/Melbourne_housing_FULL.csv",
                    na = c("", "NA", "#N/A"),
                    show_col_types = FALSE) |>
  clean_names() |>
  distinct() |>
  filter(!is.na(price), !is.na(regionname)) |>
  mutate(
    type = factor(type, levels = c("h", "u", "t"),
                  labels = c("House", "Unit", "Townhouse")),
    method = factor(method,
                    levels = c("S", "SP", "PI", "VB", "SA"),
                    labels = c("Sold", "Sold prior", "Passed in",
                               "Vendor bid", "Sold after auction")),
    region_group = if_else(str_detect(regionname, "Victoria"),
                           "Regional Victoria", regionname) |>
      factor()
  ) |>
  select(price, rooms, distance, bathroom, car,
         type, method, region_group)

# Fit the best model to the entire data set 
# random forest with the mtry chosen by cross-validation in index.qmd
housing_recipe <- recipe(price ~ rooms + distance + bathroom + car +
                           type + method + region_group,
                         data = housing) |>
  step_impute_median(bathroom, car)

rf_spec <- rand_forest(mtry = 3, trees = 500) |>
  set_engine("ranger") |>
  set_mode("regression")

# seed so the random forest (and its predictions) is the same every time
set.seed(558)
final_model <- workflow() |>
  add_recipe(housing_recipe) |>
  add_model(rf_spec) |>
  fit(data = housing)

#* @apiTitle Melbourne Housing Price API
#* @apiDescription Predict Melbourne property sale prices with a random forest.

#* Predict the sale price of a property
#* Defaults are the mean of each numeric predictor and the most common level
#* of each categorical predictor.
#* @param rooms Number of rooms
#* @param distance Distance from the Melbourne CBD (km)
#* @param bathroom Number of bathrooms
#* @param car Number of car spaces
#* @param type Property type: House, Unit, or Townhouse
#* @param method Sale method: Sold, Sold prior, Passed in, Vendor bid, or Sold after auction
#* @param region_group Region: Eastern Metropolitan, Northern Metropolitan, Regional Victoria, South-Eastern Metropolitan, Southern Metropolitan, or Western Metropolitan
#* @serializer unboxedJSON
#* @get /pred
function(rooms = 2.9924, distance = 11.2806, bathroom = 1.5917, car = 1.7154,
         type = "House", method = "Sold",
         region_group = "Southern Metropolitan") {

  # check that each categorical input is one of the levels the model knows
  if (!type %in% levels(housing$type)) {
    return(list(error = paste("type must be one of:",
                              paste(levels(housing$type), collapse = ", "))))
  }
  if (!method %in% levels(housing$method)) {
    return(list(error = paste("method must be one of:",
                              paste(levels(housing$method), collapse = ", "))))
  }
  if (!region_group %in% levels(housing$region_group)) {
    return(list(error = paste("region_group must be one of:",
                              paste(levels(housing$region_group), collapse = ", "))))
  }

  # inputs arrive as text in the URL, so convert them to the right types
  new_sale <- tibble(
    rooms = as.numeric(rooms),
    distance = as.numeric(distance),
    bathroom = as.numeric(bathroom),
    car = as.numeric(car),
    type = factor(type, levels = levels(housing$type)),
    method = factor(method, levels = levels(housing$method)),
    region_group = factor(region_group, levels = levels(housing$region_group))
  )

  pred_price <- predict(final_model, new_data = new_sale)$.pred

  list(inputs = new_sale,
       predicted_price = round(pred_price, 0))
}

# Example calls (copy and paste into a browser while the API is running):
# http://localhost:8000/pred
# http://localhost:8000/pred?rooms=2&distance=5&bathroom=1&car=1&type=Unit&method=Sold&region_group=Northern%20Metropolitan
# http://localhost:8000/pred?rooms=4&distance=15&bathroom=2&car=2&type=House&method=Sold%20prior&region_group=Eastern%20Metropolitan

#* Information about this API
#* @serializer unboxedJSON
#* @get /info
function() {
  list(name = "Javi Brito",
       github_pages = "https://itsjavi16.github.io/ST558-Final-Project/")
}
