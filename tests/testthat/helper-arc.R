# Fake ArcGIS responses for mocking acti_arc_request().
fake_fields <- list(
  list(name = "OBJECTID", type = "esriFieldTypeOID"),
  list(name = "GEOID10", type = "esriFieldTypeString"),
  list(name = "NatWalkInd", type = "esriFieldTypeDouble"),
  list(name = "TotPop", type = "esriFieldTypeInteger")
)

fake_features_json <- function(ids) {
  feats <- lapply(ids, function(i) {
    list(attributes = list(
      OBJECTID = i,
      GEOID10 = sprintf("%012d", i),
      NatWalkInd = (i %% 19) + 1,
      TotPop = i * 10L
    ))
  })
  as.character(jsonlite::toJSON(
    list(fields = fake_fields, features = feats),
    auto_unbox = TRUE, digits = NA
  ))
}

# Returns a mock acti_arc_request() that serves `object_ids` and records
# every call's params in `env$calls`.
fake_arc_server <- function(object_ids, env = new.env()) {
  env$calls <- list()
  fn <- function(url, params = list()) {
    env$calls[[length(env$calls) + 1]] <- c(list(url = url), params)
    if (identical(params$returnIdsOnly, "true")) {
      return(as.character(jsonlite::toJSON(
        list(objectIdFieldName = "OBJECTID", objectIds = object_ids),
        auto_unbox = FALSE
      )))
    }
    if (identical(params$where, "1=0")) {
      return(as.character(jsonlite::toJSON(
        list(fields = fake_fields, features = list()), auto_unbox = TRUE
      )))
    }
    ids <- as.integer(strsplit(params$objectIds, ",")[[1]])
    fake_features_json(ids)
  }
  list(fn = fn, env = env)
}
