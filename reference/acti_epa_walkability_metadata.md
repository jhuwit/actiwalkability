# Get EPA Walkability Index layer metadata

Opens the EPA Walkability Index ArcGIS layer and returns its metadata.
This includes the available fields, layer extent, geometry type, and
service limits such as \`maxRecordCount\`.

## Usage

``` r
acti_epa_walkability_metadata()
```

## Value

A \`FeatureLayer\` object, which is a list containing the ArcGIS layer
metadata.

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
