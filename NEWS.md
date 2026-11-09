# actiwalkability (development version)

* 'arcgislayers' moved from Imports to Suggests. It is only needed by
  `acti_epa_walkability()` and `acti_epa_walkability_metadata()`, which already
  check for it with `rlang::check_installed()`. This drops sf, terra, s2, units
  and their GDAL/GEOS/PROJ system requirements from a default install.

# actiwalkability 0.1.0

* Initial CRAN submission.
* Added in vignette.
* Added in `acti_epa_walkability_metadata`.
