
# ST558 Final Project: Predicting Melbourne Housing Prices

This project fits and compares predictive models for residential property sale
prices in Melbourne, Australia, then serves the best model through an API that
runs inside a Docker container.

**Rendered modeling page:** https://itsjavi16.github.io/ST558-Final-Project/

## Project overview

1. **Modeling (`index.qmd`):** Using the `tidymodels` framework, the data is
   split into a training set (70%) and test set (30%). A regression tree and a
   random forest are each tuned with 5-fold cross-validation, using RMSE as the
   metric. The best model from each family is compared on the test set, and the
   overall winner is fit to the entire data set.
2. **API (`myAPI.R`):** A `plumber` API that refits the best model and returns
   price predictions.
3. **Docker (`Dockerfile`):** Builds an image that runs the API.

## Data

The data comes from the
[Melbourne Housing Market dataset on Kaggle](https://www.kaggle.com/datasets/anthonypino/melbourne-housing-market),
which contains property sales from January 2016 to March 2018. After removing
sales without a recorded price, 27,244 sales remain. The response is sale
`price`, and the predictors are number of rooms, distance from the CBD, number
of bathrooms, number of car spaces, property type, sale method, and region.

## Results

| Model | Test RMSE | Test MAE |
|---|---|---|
| Regression tree | $375,047 | $219,768 |
| **Random forest** (`mtry = 3`) | **$363,100** | **$208,764** |

The random forest had the lower test set error and was chosen as the final
model.

## Repository contents

| File / folder | Description |
|---|---|
| `index.qmd` | Modeling file: introduction, data cleaning, metric, regression tree, random forest, and final model selection |
| `docs/` | Rendered website for GitHub Pages |
| `myAPI.R` | Plumber API with `pred` and `info` endpoints |
| `Dockerfile` | Instructions to build the Docker image for the API |
| `data/Melbourne_housing_FULL.csv` | Raw data used by the modeling file and the API |

The saved Docker image (`.tar`) is too large for GitHub and is shared
separately through Google Drive.

## Running the API with Docker

Build the image and start a container:

```bash
docker build -t melbourne-api .
docker run --rm -p 8000:8000 melbourne-api
```

Once it shows `Running plumber API`, open http://localhost:8000/__docs__/ or
try these example calls:

- http://localhost:8000/info
- http://localhost:8000/pred
- http://localhost:8000/pred?rooms=2&distance=5&bathroom=1&car=1&type=Unit&method=Sold&region_group=Northern%20Metropolitan

### Endpoints

- **`/pred`:** returns a predicted sale price. Every input is optional. The
  defaults are the mean of each numeric predictor and the most common level of
  each categorical predictor.
- **`/info`:** returns the author's name and the URL of the rendered GitHub
  Pages site.

## R packages

`tidyverse`, `tidymodels`, `janitor`, `rpart`, `ranger`, `plumber`