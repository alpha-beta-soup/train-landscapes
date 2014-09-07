train-landscapes
================

Viewshed analysis of a line feature draped over a DEM

How to
------

First, obtain a raster digital elevation model. Edit the variable R_DEM to point to it. Viewshed will be determined on this surface.

Secondly, obtain a line vector feature (a shapefile's good). Edit the variable LINE_SHP tp point to it. You may like to simplify the line or edit out the tunnels (where nothing is generally visible).

1. In a terminal: $ grass64
2. (Set up your GRASS workspace)
3. Execute $ sh generate_los.sh
4. Examine your result.

Note that for a very long and/or detailed line feature and/or a high-resolution DEM and/or a large DIST\_PTS variable and/or a large MAX\_VIS\_DIST the procedure can take several hours to complete. You might like to test with non-default values first.

Requirements
------------

Assumes [GRASS 6.4](http://grass.osgeo.org/); see original repo (by [@pierreroudier](https://github.com/pierreroudier)) for a GRASS 7.0 equivalent.
