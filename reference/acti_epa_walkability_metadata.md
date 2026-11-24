# Get EPA Walkability Index layer metadata

Requests the EPA Walkability Index ArcGIS layer description and returns
its metadata. This includes the available fields, layer extent, geometry
type, and service limits such as `maxRecordCount`.

## Usage

``` r
acti_epa_walkability_metadata()
```

## Value

A list containing the ArcGIS layer metadata, with `fields` as a
`data.frame` and the layer `url` added.

## Note

See
<https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0>

## Examples

``` r
if (FALSE) { # \dontrun{
metadata <- acti_epa_walkability_metadata()
metadata$fields
} # }
```
