#!/bin/bash

LINE_SHP='../data/roads_test.shp' # Roads shapefile
R_DEM='../data/nidemreproj' # Elevation DEM
PTS_FILE="../data/road_points_coords.csv" # An intermediate output of this script; coordinates of LINE_SHP
DIST_PTS=25 # Ideally the resolution of the DEM
MAX_VIS_DIST=30000 # Maximum distance visible
ELEV=2 # Metres above the ground that the observer stands (note, try include the vehicle, too)

# Load shapefile into GRASS
v.in.ogr dsn=$LINE_SHP output=road -o --verbose

# Load elevation raster into GRASS and set it as the computational region
r.in.gdal --o input=$R_DEM output=dem --verbose

# Sample points along line
v.to.points -ivt in=road out=roads_points dmax=$DIST_PTS --o --q

# Put point coordinates in text file
v.out.ascii -r in=roads_points fs=, --quiet | awk -F "\"*,\"*" '{print $1","$2}' > $PTS_FILE

NPTS=`cat $PTS_FILE | wc -l`

# Solution using r.los (r.viewshed in GRASS 7.0)
# ==============================================

echo -n "\nComputing viewsheds\n"

COUNTER=0
while read -r line
  do
  
  PCT_FLOAT=$(echo "100*$((COUNTER+1))/$NPTS" | bc -l)
  PCT=`printf "%0.1f\n" $PCT_FLOAT` 

  echo -ne "Processing $NPTS viewshed instances: \t $PCT % \r" 
  
  # Set the region to a smaller subset around the current observer point
  # to speed processing
  x=$(echo $line | cut -f1 -d,)
  y=$(echo $line | cut -f2 -d,)
   
  W=$(echo "$x-$MAX_VIS_DIST" | bc -l)
  E=$(echo "$x+$MAX_VIS_DIST" | bc -l)
  N=$(echo "$y+$MAX_VIS_DIST" | bc -l)
  S=$(echo "$y-$MAX_VIS_DIST" | bc -l)
  
  g.region n=$N s=$S e=$E w=$W
  
  r.los input=dem output=tmp_los_${COUNTER} coordinate=$line obs_elev=$ELEV max_dist=$MAX_VIS_DIST --o
  COUNTER=$((COUNTER+1))
  
done < $PTS_FILE

echo "\n"

# Set computational region to full extent
g.region -pm rast=dem --verbose

# Combine results in a single map 
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
r.series in=`g.mlist --q type=rast pat=tmp_los_* sep=,` out=total_los method=sum --o --q

# Create distance to road map
v.to.rast in=road out=road use=val val=1 --o --q
r.grow.distance -m input=road distance=dist_from_road --o --q

# Use distance to road instead of viewing angle in the
# viewshed result map 
r.mapcalc "dist_los = if(total_los, dist_from_road, null())"

# Clean up, removing the component visibility rasters
g.mremove -f "tmp_los_*" --v
