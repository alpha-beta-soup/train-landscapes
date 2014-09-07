train-landscapes
================

Viewshed analysis of a line feature draped over a DEM.

How to
------

First, obtain a raster digital elevation model. Edit the variable `R_DEM` to point to it. Viewshed will be determined on this surface.

Secondly, obtain a line vector feature (a shapefile's good). Edit the variable `LINE_SHP` to point to it. You may like to simplify the line or edit out the tunnels (where nothing is generally visible). The viewshed will be determined using a sample of points along this line as observer locations.

1. In a terminal: `$ grass64`
2. (Set up your GRASS workspace)
3. Execute `$ sh generate_los.sh`
4. Examine your result.

Note that for a very long and/or detailed line feature and/or a high-resolution DEM and/or a large `DIST_PTS` variable and/or a large `MAX_VIS_DIST` the procedure can take several hours to complete. You might like to test with non-default values first.

Requirements
------------

Assumes [GRASS 6.4](http://grass.osgeo.org/); see original repo (by [@pierreroudier](https://github.com/pierreroudier)) for a GRASS 7.0 equivalent.

Inspired by
-----------

A long beautiful [train journey](http://www.kiwirailscenic.co.nz/northern-explorer/) in New Zealand, the economics of choosing a train over driving, and this [blog post](http://datagistips.blogspot.co.nz/2011/09/on-road-with-r-grass-intervisibility.html) on doing the same thing with R/GRASS.

![Tranz Scenic's Northern Explorer, with the volcanic zone in the background](https://github.com/alpha-beta-soup/train-landscapes/blob/master/img.jpg)
