# image that already has R and the tidyverse installed
FROM rocker/tidyverse:4.6.2

# system library needed by the plumber package
RUN apt-get update -qq && apt-get install -y --no-install-recommends libsodium-dev

# install the R packages the API uses
RUN R -e "install.packages(c('tidymodels', 'janitor', 'ranger', 'plumber'))"

# copy the API file and the data into the image
WORKDIR /app
COPY myAPI.R myAPI.R
COPY data/Melbourne_housing_FULL.csv data/Melbourne_housing_FULL.csv

# the API listens on port 8000
EXPOSE 8000

# start the API when a container runs
ENTRYPOINT ["R", "-e", "pr <- plumber::plumb('myAPI.R'); pr$run(host = '0.0.0.0', port = 8000)"]