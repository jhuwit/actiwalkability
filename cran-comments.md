## R CMD check results

0 errors | 0 warnings | 0 notes

## Update

This is an update from 0.1.0. Main changes:

* The 'arcgislayers' dependency has been removed; the EPA ArcGIS REST service
  is queried directly with 'curl' and 'jsonlite'. 'sf' moved to Suggests.
* Breaking: `acti_epa_walkability()` now defaults to `geometry = FALSE`.

## Reverse dependencies

There are currently no reverse dependencies.

## Internet resources

Examples that query the EPA service are in `\donttest{}` and only run if the
service responds. The vignette does not evaluate network code, and tests that
use the live service are skipped on CRAN.
