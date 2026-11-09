# actiwalkability (development version)

* 'arcgislayers' is no longer used. `acti_epa_walkability()` and
  `acti_epa_walkability_metadata()` now call the EPA ArcGIS REST service
  directly with 'curl' and 'jsonlite'. This drops sf, terra, s2, units and
  their GDAL/GEOS/PROJ system requirements from a default install.
* `acti_epa_walkability()` gains explicit `fields`, `filter_geom`,
  `predicate`, and `n_max` arguments (previously passed through to
  `arcgislayers::arc_select()`); other named arguments in `...` are sent as
  ArcGIS query parameters. Records are requested in chunks of the service's
  `maxRecordCount` (1000).
* **Breaking:** `geometry` now defaults to `FALSE`, returning a tibble of
  attributes. Previously the default was `TRUE`, and even `geometry = FALSE`
  returned an `sf` object with empty geometries. `geometry = TRUE` returns an
  `sf` object in EPSG:3857 (as before) and needs 'sf', now in Suggests.
* `acti_epa_walkability_metadata()` returns a plain list (with `fields` as a
  `data.frame` and the layer `url`) instead of an arcgislayers `FeatureLayer`.
* GEOIDs containing single quotes are escaped in the `where` clause.

# actiwalkability 0.1.0

* Initial CRAN submission.
* Added in vignette.
* Added in `acti_epa_walkability_metadata`.
