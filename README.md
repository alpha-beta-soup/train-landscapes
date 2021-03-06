train-landscapes
================

Viewshed analysis of a line feature draped over a DEM.

How to
------

First, obtain a raster digital elevation model. Edit the variable `R_DEM` to point to it. Viewshed will be determined on this surface.

Secondly, obtain a line vector feature (a shapefile's good). Edit the variable `LINE_SHP` to point to it. You may like to simplify the line or edit out the tunnels (where nothing is generally visible). The viewshed will be determined using a sample of points along this line as observer locations.

1. In a terminal: `$ grass64` or `$ grass70` as per what version of GRASS GIS you are using. (GRASS 7.0 will be faster for this task.)
2. Set up and/or connect to the GRASS workspace where your project data is available and will be stored.
3. Type `$ sh generate_los.sh` *or* `$ sh generate_los_70.sh` according to your GRASS GIS version, in the command line. Note that while GRASS 6.4 is the current stable release, the viewshed functionality in GRASS 7 is improved in performance and in cabability. Indeed, the maximum visible distance is adjusted in the GRASS 6.4 script to reflect the fact that the documentation of `r.los` suggests a maximum of 1000 rows and columns in the input raster used for the visibility analysis (given its resolution). The GRASS 7 script does not require this (`r.viewshed`).
4. Add an argument to this statement: either `-train` or `-road` depending on whether you want to run the intervisibility analysis for the road route, or the rail route.
5. Execute your command, and wait (probably a very long time).
6. Examine your result (enter `exit` to quit GRASS).
7. Create tiles/tweak your slippy map.
8. ????
9. Profit.

Note that for a very long and/or detailed line feature and/or a high-resolution DEM and/or a large `DIST_PTS` variable and/or a large `MAX_VIS_DIST` the procedure can take several hours to complete. You might like to test with non-default values first.

Requirements
------------

`generate_los.sh` assumes [GRASS 6.4](http://grass.osgeo.org/). For GRASS 7.0 (currently not the stable release), use `generate_los_70.sh` or see original repo (by [@pierreroudier](https://github.com/pierreroudier)).

I used QTiles, a QGIS plugin, to create tiles. There are other methods.

Inspired by
-----------

A long, beautiful [train journey](http://www.kiwirailscenic.co.nz/northern-explorer/) in New Zealand, the economics of choosing a train over driving, and this [blog post](http://datagistips.blogspot.co.nz/2011/09/on-road-with-r-grass-intervisibility.html) on doing the same thing with R/GRASS.

![Tranz Scenic's Northern Explorer, with the volcanic zone in the background](https://github.com/alpha-beta-soup/train-landscapes/blob/Web-ify/blog/img.jpg)
