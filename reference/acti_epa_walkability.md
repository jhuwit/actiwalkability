# Get EPA Walkability Index

Queries the EPA National Walkability Index ArcGIS layer directly through
its REST API. Results are requested in chunks of the service's
`maxRecordCount`, so large selections are returned in full.

## Usage

``` r
acti_epa_walkability(
  geoid,
  geometry = FALSE,
  fields = NULL,
  filter_geom = NULL,
  predicate = "intersects",
  n_max = Inf,
  ...
)
```

## Arguments

- geoid:

  GEOID10 of the area of interest. This should be a 12 character string.
  If `NULL`, then all GEOIDs are selected (subject to `filter_geom`).
  This can be a lot of data, so use with caution.

- geometry:

  Should block-group polygons be returned? If `TRUE`, the result is an
  `sf` object in Web Mercator (EPSG:3857), which requires the sf
  package. If `FALSE` (default), a tibble of attributes.

- fields:

  Character vector of fields to return. `NULL` (default) returns all
  fields. See `acti_epa_walkability_metadata()$fields`.

- filter_geom:

  Optional spatial filter: an `sf`, `sfc`, `sfg`, or `bbox` object
  (requires sf). Multiple features are unioned. Inputs with a CRS are
  transformed to WGS 84 (EPSG:4326). An `sfg` has no CRS, so it is
  assumed to already be in longitude/latitude (EPSG:4326); passing
  projected coordinates as an `sfg` gives a wrong spatial filter.

- predicate:

  Spatial relationship between the layer and `filter_geom`: one of
  `"intersects"`, `"contains"`, `"crosses"`, `"envelope_intersects"`,
  `"index_intersects"`, `"overlaps"`, `"touches"`, or `"within"`.

- n_max:

  Maximum number of records to return.

- ...:

  Additional named ArcGIS query parameters passed to the layer's `query`
  endpoint (see the ArcGIS REST API "Query (Map Service/Layer)"
  documentation).

## Value

A tibble (or an `sf` object if `geometry = TRUE`) with a
`cat_walk_index` factor added when `NatWalkInd` is returned.

## Note

See
<https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0>

## Examples

``` r
# \donttest{
# Only run if the EPA ArcGIS service responds
epa_up <- tryCatch(
  curl::curl_fetch_memory(
    "https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0?f=json",
    handle = curl::new_handle(timeout = 10)
  )$status_code == 200,
  error = function(e) FALSE
)
if (epa_up) {
  acti_epa_walkability(c("240054519002", "240054026041", "245102303002"))
}
#> # A tibble: 3 × 183
#>   GEOID10      GEOID20    STATEFP COUNTYFP TRACTCE BLKGRPCE CSA   CSA_Name CBSA 
#>   <chr>        <chr>      <chr>   <chr>    <chr>   <chr>    <chr> <chr>    <chr>
#> 1 240054519002 240054519… 24      005      451900  2        548   Washing… 12580
#> 2 245102303002 245102303… 24      510      230300  2        548   Washing… 12580
#> 3 240054026041 240054026… 24      005      402604  1        548   Washing… 12580
#> # ℹ 174 more variables: CBSA_Name <chr>, CBSA_POP <dbl>, CBSA_EMP <dbl>,
#> #   CBSA_WRK <dbl>, Ac_Total <dbl>, Ac_Water <dbl>, Ac_Land <dbl>,
#> #   Ac_Unpr <dbl>, TotPop <dbl>, CountHU <dbl>, HH <dbl>, P_WrkAge <dbl>,
#> #   AutoOwn0 <dbl>, Pct_AO0 <dbl>, AutoOwn1 <dbl>, Pct_AO1 <dbl>,
#> #   AutoOwn2p <dbl>, Pct_AO2p <dbl>, Workers <dbl>, R_LowWageWk <dbl>,
#> #   R_MedWageWk <dbl>, R_HiWageWk <dbl>, R_PCTLOWWAGE <dbl>, TotEmp <dbl>,
#> #   E5_Ret <dbl>, E5_Off <dbl>, E5_Ind <dbl>, E5_Svc <dbl>, E5_Ent <dbl>, …
# }
```
