library("caret") # install.packages("RANN")
library(RANN)
library(tidyverse)

afdata = read.csv("../Clustering-Algorithms/data/afdata_full.csv", header = TRUE, dec = ".", sep = ",")

# Type of variables

lapply(afdata, class)

#impute FIXBI2 filling up with zeros NAs until find a non-NA value

n=length(afdata$FIXBI2)
i=1
while (i<=n)
{
  
  if (is.na(afdata$FIXBI2[i])) {
    afdata$FIXBI2[i] <-0
    i=i+1
    next
  }
  
  print(paste (afdata$Country[i], " : ",afdata$FIXBI2[i]))
  #move to the next country
  while (afdata$Year[i]!=1995 & i<=n){
    i=i+1
  }
}


# Select for imputation of KNNs

afdata <- afdata %>% 
  select(Country, Year, PATEN2, STJOU2)

# inpute data

k_value=5



knn_imput = function(afdata) {
  numeric_columns = (sapply(afdata, class) %in% c("numeric", "integer"))
  means = apply(afdata[, numeric_columns], 2, mean, na.rm = TRUE)
  sds = apply(afdata[, numeric_columns], 2, sd, na.rm = TRUE)
  
  afdata[, numeric_columns] = sweep(afdata[, numeric_columns], 2, means)
  afdata[, numeric_columns] = sweep(afdata[, numeric_columns], 2, sds, "/")
  
  imputer = preProcess(afdata, method = "knnImpute", k=k_value)
  
  imputed_data =  predict(imputer, newdata = afdata)
  
  imputed_data[, numeric_columns] = sweep(
    imputed_data[, numeric_columns], 2, sds, "*"
  )
  imputed_data[, numeric_columns] = sweep(
    imputed_data[, numeric_columns], 2, means, "+"
  )
  
  imputed_data
}

imputed_data_innovation = knn_imput(afdata)

# "mark" imputed data

numeric_columns = which(sapply(afdata, class) %in% c("numeric", "integer"))
modified_afdata = afdata

for (col in numeric_columns) {
  indices = is.na(afdata[, col])
  modified_afdata[indices, col] = (
    format(round(imputed_data[indices, col], 3), nsmall = 3)
  )
}

# Generate a list of dataframes. Knns using k = 5

df_list <- list(imputed_data_educ, imputed_data_ict, imputed_data_innovation, imputed_data_inst)
library(reshape)
data <-merge_recurse(df_list)
write.csv(data, "afdata_imputed.csv")

