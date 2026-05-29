# actiwalkability

`actiwalkability` provides helpers for querying the EPA Walkability
Index and working with Census GEOID/FIPS identifiers.

Core entry points:

- `ww_epa_walkability()` for querying the EPA Walkability Index ArcGIS
  layer
- `ww_fips15()` and `ww_fips12()` for composing Census FIPS/GEOID
  strings

## Installation

You can install `actiwalkability` from GitHub with:

``` r

# install.packages("remotes")
remotes::install_github("jhuwit/actiwalkability")
```

## Quick Start

``` r

library(actiwalkability)

ww_fips12(24, 510, 60400, block = 2002)

ww_epa_walkability(
  c("240054519002", "240054026041", "245102303002")
)
```
