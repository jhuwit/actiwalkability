# Get Census Tract FIPS codes

Get Census Tract FIPS codes

## Usage

``` r
acti_fips15(state, county, tract, block = NA)

acti_fips12(state, county, tract, block = NA)
```

## Arguments

- state:

  2-digit state FIPS code.

- county:

  3-digit county FIPS code.

- tract:

  6-digit tract FIPS code.

- block:

  4-digit block FIPS code. If omitted or \`NA\`, tract-level codes are
  returned.

## Value

An 11-to-15 digit GEOID/FIPS code.

## Examples

``` r
suppressWarnings(acti_fips15(24, 510, 60400))
#> [1] "24510060400"
acti_fips15(24, 510, 60400, block = 2002)
#> [1] "245100604002002"
acti_fips12(24, 510, 60400, block = 2002)
#> [1] "245100604002"
```
