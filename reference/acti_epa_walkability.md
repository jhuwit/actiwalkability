# Get EPA Walkability Index

Get EPA Walkability Index

## Usage

``` r
acti_epa_walkability(geoid, geometry = TRUE, ...)
```

## Arguments

- geoid:

  GEOID10 of the area of interest. This should be a 12 character string.
  If \`NULL\`, then all GEOIDs are selected. This can be a lot of data,
  so use with caution.

- geometry:

  Should geometry be returned? Passed to \[arcgislayers::arc_select()\]

- ...:

  Additional arguments to pass to \[arcgislayers::arc_select()\]

## Value

A \`data.frame\` of results.

## Note

See
<https://geodata.epa.gov/arcgis/rest/services/OA/WalkabilityIndex/MapServer/0>

## Examples

``` r
acti_epa_walkability(c("240054519002", "240054026041", "245102303002"))
#> Registered S3 method overwritten by 'jsonify':
#>   method     from    
#>   print.json jsonlite
#> Simple feature collection with 3 features and 183 fields
#> Geometry type: POLYGON
#> Dimension:     XY
#> Bounding box:  xmin: -8545997 ymin: 4744132 xmax: -8492307 ymax: 4776169
#> Projected CRS: WGS 84 / Pseudo-Mercator
#>        GEOID10      GEOID20 STATEFP COUNTYFP TRACTCE BLKGRPCE CSA
#> 1 240054519002 240054519002      24      005  451900        2 548
#> 2 245102303002 245102303002      24      510  230300        2 548
#> 3 240054026041 240054026041      24      005  402604        1 548
#>                                         CSA_Name  CBSA
#> 1 Washington-Baltimore-Arlington, DC-MD-VA-WV-PA 12580
#> 2 Washington-Baltimore-Arlington, DC-MD-VA-WV-PA 12580
#> 3 Washington-Baltimore-Arlington, DC-MD-VA-WV-PA 12580
#>                       CBSA_Name CBSA_POP CBSA_EMP CBSA_WRK    Ac_Total Ac_Water
#> 1 Baltimore-Columbia-Towson, MD  2793250  1316328  1277911 25200.77594 22763.46
#> 2 Baltimore-Columbia-Towson, MD  2793250  1316328  1277911    23.79845     0.00
#> 3 Baltimore-Columbia-Towson, MD  2793250  1316328  1277911   396.07560     0.00
#>      Ac_Land   Ac_Unpr TotPop CountHU  HH P_WrkAge AutoOwn0    Pct_AO0 AutoOwn1
#> 1 2437.31409 277.03372    847     397 355    0.536        6 0.01690141      113
#> 2   23.79845  23.79845   1141     602 566    0.899       25 0.04416961      269
#> 3  396.07560 380.09043   2087     887 870    0.627        0 0.00000000      293
#>     Pct_AO1 AutoOwn2p  Pct_AO2p Workers R_LowWageWk R_MedWageWk R_HiWageWk
#> 1 0.3183099       236 0.6647887     461         100         129        232
#> 2 0.4752650       272 0.4805654     948         123         181        644
#> 3 0.3367816       577 0.6632184    1120         263         340        517
#>   R_PCTLOWWAGE TotEmp E5_Ret E5_Off E5_Ind E5_Svc E5_Ent E8_Ret E8_off E8_Ind
#> 1    0.2169197     68      3      2     11      5     47      3      2     11
#> 2    0.1297468    128      2      5     15     90     16      2      5     15
#> 3    0.2348214     68      0      0      9     59      0      0      0      9
#>   E8_Svc E8_Ent E8_Ed E8_Hlth E8_Pub E_LowWageWk E_MedWageWk E_HiWageWk
#> 1      5     47     0       0      0          43          20          5
#> 2     88     16     0       2      0          22          22         84
#> 3      0      0     0      59      0          19          40          9
#>   E_PctLowWage       D1A       D1B       D1C   D1C5_RET    D1C5_OFF   D1C5_IND
#> 1    0.6323529  1.433039  3.057390 0.2454575 0.01082901 0.007219338 0.03970636
#> 2    0.1718750 25.295767 47.944303 5.3785020 0.08403909 0.210097733 0.63029320
#> 3    0.2794118  2.333655  5.490799 0.1789048 0.00000000 0.000000000 0.02367858
#>     D1C5_SVC  D1C5_ENT   D1C8_RET    D1C8_OFF   D1C8_IND   D1C8_SVC  D1C8_ENT
#> 1 0.01804834 0.1696544 0.01082901 0.007219338 0.03970636 0.01804834 0.1696544
#> 2 3.78175920 0.6723127 0.08403909 0.210097733 0.63029320 3.69772010 0.6723127
#> 3 0.15522622 0.0000000 0.00000000 0.000000000 0.02367858 0.00000000 0.0000000
#>   D1C8_ED  D1C8_HLTH D1C8_PUB       D1D D1_FLAG   D2A_JPHH D2B_E5MIX D2B_E5MIXA
#> 1       0 0.00000000        0  1.678496       0 0.19154930 0.6109497  0.6109497
#> 2       0 0.08403909        0 30.674269       0 0.22614841 0.5905660  0.5905660
#> 3       0 0.15522622        0  2.512560       0 0.07816092 0.5638560  0.2428396
#>   D2B_E8MIX D2B_E8MIXA D2A_EPHHM D2C_TRPMX1 D2C_TRPMX2 D2C_TRIPEQ D2R_JOBPOP
#> 1 0.6109497  0.4728604 0.3343037  0.4594217  0.4985539 0.48662362 0.14863388
#> 2 0.5722914  0.4931172 0.3646479  0.4934795  0.5381128 0.47452340 0.20173365
#> 3 0.5638560  0.1879520 0.2624930  0.2519723  0.2736482 0.01527748 0.06310905
#>   D2R_WRKEMP D2A_WRKEMP   D2C_WREMLX       D3A    D3AAO      D3AMM     D3APO
#> 1  0.2570888   6.779412 3.090533e-03  4.984511 0.000000  0.5864318  4.398079
#> 2  0.2379182   7.406250 1.651205e-03 36.370332 0.000000 19.5629047 16.807427
#> 3  0.1144781  16.470588 1.910772e-07 16.162581 2.051807  0.6109743 13.499800
#>         D3B    D3BAO    D3BMM3      D3BMM4    D3BPO3   D3BPO4       D4A
#> 1  12.52027 0.000000  1.312921   0.5251683  9.978197 4.463930 -99999.00
#> 2 143.44465 0.000000 53.785020 107.5700394  0.000000 0.000000    187.76
#> 3  57.11718 4.847559  3.231706   0.0000000 67.865831 9.695119   1079.60
#>       D4B025     D4B050       D4C          D4D           D4E   D5AR   D5AE
#> 1 0.00000000 0.00000000 -99999.00 -99999.00000 -9.999900e+04  48026  43892
#> 2 0.00000000 0.08393061     14.67    394.51312  1.285714e-02 193188 152130
#> 3 0.01625141 0.27085648     19.00     30.70121  9.103977e-03  89739  85006
#>     D5BR   D5BE         D5CR     D5CRI         D5CE     D5CEI          D5DR
#> 1 -99999 -99999 0.0002271313 0.2280675 0.0002339086 0.2633246 -9.999900e+04
#> 2 401276 258562 0.0009136517 0.9174178 0.0008107288 0.9126851  1.434197e-03
#> 3  76190  43918 0.0004244062 0.4261556 0.0004530126 0.5099830  2.723099e-04
#>           D5DRI          D5DE         D5DEI D2A_Ranked D2B_Ranked D3B_Ranked
#> 1 -9.999900e+04 -9.999900e+04 -9.999900e+04          6          7          5
#> 2  4.011500e-01  1.320864e-03  4.863296e-01          6          8         17
#> 3  7.616608e-02  2.243551e-04  8.260542e-02          4          2         10
#>   D4A_Ranked NatWalkInd                                   Region Households
#> 1          1   4.166667 Baltimore-Columbia-Towson, MD Metro Area        408
#> 2         19  14.333333 Baltimore-Columbia-Towson, MD Metro Area        566
#> 3         13   8.666667 Baltimore-Columbia-Towson, MD Metro Area        937
#>   Workers_1 Residents Drivers Vehicles White Male Lowwage Medwage Highwage
#> 1       461      1002  660.00      775   987  430     100     129      232
#> 2       948      1146  992.64      902   955  566     123     181      644
#> 3      1120      2393 1911.36       NA   348  959     263     340      517
#>   W_P_Lowwage W_P_Medwage W_P_Highwage GasPrice    logd1a    logd1c logd3aao
#> 1   0.6323529   0.2941176   0.07352941      248 0.8891409 0.2195029 0.000000
#> 2   0.1718750   0.1718750   0.65625000      248 3.2694080 1.8529333 0.000000
#> 3   0.2794118   0.5882353   0.13235294      248 1.2040693 0.1645859 1.115734
#>   logd3apo d4bo25 d5dei_1 logd4d UPTpercap B_C_constant B_C_male  B_C_ld1c
#> 1 1.686043      0       0      0        35     3.005667 0.192176 -0.164587
#> 2 2.879616      0       0      6        35     2.403901 0.107901 -0.332898
#> 3 2.674135      0       0      3        35     2.578616 0.080534 -0.347318
#>   B_C_drvmveh  B_C_ld1a B_C_ld3apo  B_C_inc1 B_C_gasp B_N_constant B_N_inc2
#> 1   -0.371507 -0.093937  -0.013574 -0.637950 0.001337     3.252807 0.091080
#> 2   -0.529421 -0.014868  -0.203534 -0.621011 0.006614     3.252959 0.091073
#> 3   -0.547124 -0.007622  -0.318452 -0.590663 0.007297     3.251736 0.092032
#>   B_N_inc3 B_N_white B_N_male B_N_drvmveh  B_N_gasp  B_N_ld1a  B_N_ld1c
#> 1 0.082316 -0.039640 0.114079   -0.193298 -0.004850 -0.214665 -0.214665
#> 2 0.082466 -0.038257 0.113668   -0.192584 -0.004854 -0.214509 -0.214509
#> 3 0.083083 -0.034845 0.112377   -0.190917 -0.004858 -0.213951 -0.213951
#>   B_N_ld3aao B_N_ld3apo B_N_d4bo25 B_N_d5dei B_N_UPTpc C_R_Households C_R_Pop
#> 1   0.079713  -0.187299  -0.512321  0.042649 -0.000441         313519  828018
#> 2   0.079935  -0.187420  -0.513327  0.041535 -0.000446         239116  609032
#> 3   0.080911  -0.188360  -0.516945  0.038478 -0.000461         313519  828018
#>   C_R_Workers C_R_Drivers C_R_Vehicles C_R_White  C_R_Male C_R_Lowwage
#> 1      399047    579540.7       452113 0.5727400 0.4740187   0.2127719
#> 2      249913    432662.6       219982 0.2749117 0.4696765   0.2358181
#> 3      399047    579540.7       452113 0.5727400 0.4740187   0.2127719
#>   C_R_Medwage C_R_Highwage  C_R_DrmV NonCom_VMT_Per_Worker Com_VMT_Per_Worker
#> 1   0.2912664    0.4959616 0.4064434              5.037774           17.12400
#> 2   0.3586968    0.4054851 0.8894451              1.660546           10.74847
#> 3   0.2912664    0.4959616 0.4064434              4.440309           25.28458
#>   VMT_per_worker VMT_tot_min VMT_tot_max VMT_tot_avg GHG_per_worker Annual_GHG
#> 1       22.16177    3.427387    151.4601    23.25904       19.74614   5133.996
#> 2       12.40901    3.427387    151.4601    23.25904       11.05643   2874.672
#> 3       29.72489    3.427387    151.4601    23.25904       26.48488   6886.068
#>   Shape_Length  Shape_Area OBJECTID SLC_score                       geometry
#> 1    57534.026 170153298.7   111210  87.34443 POLYGON ((-8510407 4750923,...
#> 2     2273.780    160847.2   111506  93.93267 POLYGON ((-8528940 4760787,...
#> 3     8688.337   2684939.4   111646  82.23534 POLYGON ((-8545990 4775843,...
#>   cat_walk_index
#> 1       [1,5.75]
#> 2    (10.5,15.2]
#> 3    (5.75,10.5]
```
