# Find EPA walkability values for pre-geocoded addresses

The EPA National Walkability Index is reported for Census block groups.
That makes a Census block-group GEOID (the 12-character `GEOID10` value)
the useful link between an address-level data set and the EPA layer.

This vignette starts after geocoding: it uses a small address lookup
that already contains a GEOID. It therefore does not send any addresses
to a geocoding service and does not require a geocoding package.

## Start with an address-to-GEOID lookup

Keep addresses and GEOIDs as character vectors. In particular, a GEOID
must not be converted to a number because leading zeroes are meaningful.

``` r

addresses <- dplyr::tibble(
  address_id = c("address_1", "address_2", "address_3"),
  address = c(
    "Pre-geocoded address in Baltimore County, MD",
    "Pre-geocoded address in Baltimore County, MD",
    "Pre-geocoded address in Baltimore City, MD"
  ),
  geoid = c("240054519002", "240054026041", "245102303002")
)

addresses
#> # A tibble: 3 × 3
#>   address_id address                                      geoid       
#>   <chr>      <chr>                                        <chr>       
#> 1 address_1  Pre-geocoded address in Baltimore County, MD 240054519002
#> 2 address_2  Pre-geocoded address in Baltimore County, MD 240054026041
#> 3 address_3  Pre-geocoded address in Baltimore City, MD   245102303002
```

The GEOIDs in this example are Census 2010 block-group identifiers,
which is the geography used by the EPA layer queried by
[`acti_epa_walkability()`](https://jhuwit.github.io/actiwalkability/reference/acti_epa_walkability.md).
When a source instead provides state, county, tract, and block
identifiers,
[`acti_fips12()`](https://jhuwit.github.io/actiwalkability/reference/acti_fips.md)
can construct the block-group GEOID:

``` r

acti_fips12(state = 24, county = 510, tract = 60400, block = 2002)
#> [1] "245100604002"
```

## Query the EPA layer

Pass the unique GEOIDs to
[`acti_epa_walkability()`](https://jhuwit.github.io/actiwalkability/reference/acti_epa_walkability.md).
Setting `geometry = FALSE` keeps the request small when only the index
attributes are needed. This call uses the live EPA ArcGIS service, so it
is left unevaluated when the vignette is built.

``` r

walkability <- acti_epa_walkability(
  unique(addresses$geoid),
  geometry = FALSE
)

walkability
```

The returned data include `GEOID10`, `NatWalkInd`, and, when the index
is available, `cat_walk_index`. `cat_walk_index` is a four-level
categorization created from the EPA national walkability index breaks.
The EPA service may also return other layer attributes.

## Attach values back to addresses

Join on the two character GEOID fields. Keeping all address rows retains
multiple addresses within the same block group.

``` r

address_walkability <- dplyr::left_join(
  addresses,
  walkability,
  by = c("geoid" = "GEOID10")
)

dplyr::select(
  address_walkability,
  address_id, address, geoid, NatWalkInd, cat_walk_index
)
```

## Geocoding is a separate step and Census vintage matters

This package deliberately consumes GEOIDs rather than geocoding street
addresses. Prepare and quality-check the address-to-GEOID crosswalk
upstream, then use the workflow above. For projects that need a
Census-geocoder client,
[`censusxy`](https://github.com/chris-prener/censusxy) is one option: it
calls the U.S. Census Bureau Geocoding Tools and is designed to batch
unique addresses. Its repository notes that it is no longer under active
development as of early 2025, so check its current status and validate
matches before using it in a production workflow.

`censusxy` does not return columns named `GEOID10` or `GEOID20`. With
`return = "geographies"`, it returns Census geography components such as
`cxy_state_id`, `cxy_county_id`, `cxy_tract_id`, and `cxy_block_id`; its
`vintage` argument determines the Census geography vintage. A
block-group GEOID can then be constructed from those components with
[`acti_fips12()`](https://jhuwit.github.io/actiwalkability/reference/acti_fips.md).
Do not run the following code as part of this package’s workflow: it is
an illustration of a possible upstream geocoding step and requires
`censusxy`.

``` r

geocoded <- censusxy::cxy_geocode(
  address_data,
  street = "street",
  city = "city",
  state = "state",
  zip = "zip",
  return = "geographies",
  vintage = "Census2010_Current"
)

geocoded$geoid <- acti_fips12(
  geocoded$cxy_state_id,
  geocoded$cxy_county_id,
  geocoded$cxy_tract_id,
  geocoded$cxy_block_id
)
```

Here, the `10` and `20` suffixes mean *Census boundary vintage*, not
GEOID length: both a 2010 and a 2020 block-group identifier contain 12
digits. The EPA Walkability Index layer is based on Census 2010 block
groups, and this package intentionally queries and joins its non-null,
12-character `GEOID10` field. The same layer also exposes a nullable
`GEOID20` field, but its alias describes a “Census block group 12-digit
FIPS code (2018)” and its declared length is 50. Those contradictory
labels do not establish a reliable Census 2020 key. Consequently,
`GEOID20` is not used by this package. The Census Geocoder currently
offers the `Census2010_Current` geography vintage for its current
benchmark; otherwise, a 2020-vintage result should be converted with an
appropriate Census crosswalk before it is joined to this EPA release.
Never treat similarly shaped 12-digit identifiers from different
vintages as interchangeable.

Other approaches include calling the [Census Geocoder
API](https://geocoding.geo.census.gov/geocoder/Geocoding_Services_API.html)
directly, using a local or commercial geocoder, or obtaining GEOIDs from
a trusted data provider. Regardless of the method, confirm that the
result is a 12-character Census 2010 block-group GEOID before passing it
to
[`acti_epa_walkability()`](https://jhuwit.github.io/actiwalkability/reference/acti_epa_walkability.md).

## Requesting other EPA attributes or a study area

The EPA service exposes more than the overall `NatWalkInd` score. Of
particular interest are the four inputs used to create it: `D2A_EPHHM`
(employment and household density), `D2B_E8MIXA` (employment and
household mix), `D3b` (street-intersection density), and `D4a` (distance
to the nearest transit stop). The matching `*_Ranked` fields provide
their national ranks. Population, household, worker, land-area, and
metropolitan-area fields are also useful for describing or screening the
returned block groups.

All
[`arcgislayers::arc_select()`](https://rdrr.io/pkg/arcgislayers/man/arc_select.html)
arguments can be passed through
[`acti_epa_walkability()`](https://jhuwit.github.io/actiwalkability/reference/acti_epa_walkability.md).
For example, use `fields` to limit the attributes downloaded, or
`filter_geom` and `predicate` to select block groups that intersect a
study-area geometry. Do not call `acti_epa_walkability(NULL)` without a
spatial filter: it requests the entire national layer.

``` r

study_area_walkability <- acti_epa_walkability(
  geoid = NULL,
  geometry = FALSE,
  filter_geom = study_area,
  predicate = "intersects",
  fields = c("GEOID10", "NatWalkInd", "D2A_EPHHM", "D2B_E8MIXA", "D3b", "D4a")
)
```
