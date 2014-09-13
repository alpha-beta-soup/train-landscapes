#!/bin/bash

LINE_SHP='../data/roads.shp' # Roads shapefile
R_DEM='../data/nidemreproj' # Elevation DEM
PTS_FILE="../data/road_points_coords.csv" # An intermediate output of this script; coordinates of LINE_SHP
R_RES=25 # The resolution of the DEM (metres)
DIST_PTS=25 # Maximum distance between observer points: ideally the resolution of the DEM
MAX_VIS_DIST=30000 # Maximum distance visible
ELEV=1.2 # Metres above the ground that the observer stands (note, try include the vehicle, too)

# Load shapefile into GRASS
v.in.ogr dsn=$LINE_SHP output=road --o --v

# Load elevation raster into GRASS and set it as the computational region
r.in.gdal --o input=$R_DEM output=dem --verbose

# Sample points along line
v.to.points -it in=road out=roads_points dmax=$DIST_PTS --o --q

# Put point coordinates in text file
v.out.ascii in=roads_points separator=, --quiet | awk -F "\"*,\"*" '{print $1","$2}' > $PTS_FILE

NPTS=`cat $PTS_FILE | wc -l`

# Solution using r.los (r.viewshed in GRASS 7.0)
# ==============================================

echo -n "\nComputing viewsheds\n"

COUNTER=0
while read -r line
  do
  
  PCT_FLOAT=$(echo "100*$((COUNTER+1))/$NPTS" | bc -l)
  PCT=`printf "%0.1f\n" $PCT_FLOAT`

  echo -ne "Processing $NPTS viewshed instances: \t $PCT % ($((COUNTER+1))/$NPTS) \r" 
  
  # Set the region to a smaller subset around the current observer point
  #   to speed processing
  x=$(echo $line | cut -f1 -d,)
  y=$(echo $line | cut -f2 -d,)
  W=$(echo "$x-$MAX_VIS_DIST" | bc -l)
  E=$(echo "$x+$MAX_VIS_DIST" | bc -l)
  N=$(echo "$y+$MAX_VIS_DIST" | bc -l)
  S=$(echo "$y-$MAX_VIS_DIST" | bc -l)
  g.region n=$N s=$S e=$E w=$W --q
  
  # Does not overwrite, so SIGINT (Ctrl+C) can be used to interrupt a
  #  long-running process, to be resumed later
  #  (keep parameters constant between runs)
  r.viewshed -crb input=dem output=tmp_los_${COUNTER} coordinates=$line obs_elev=$ELEV max_dist=$MAX_VIS_DIST memory=2000 --o --q
  COUNTER=$((COUNTER+1))
  
done < $PTS_FILE

# Combine results in a single map 
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
echo "\nCombining component viewsheds\n"
# Loops because it can exceed hard limit of number of rasters that can be open at once (1024)
# r.series -z flag, new in grass70, "don't keep files open"
for i in `seq 0 9`;
do
  # Set computational region to full extent
  g.region -pm rast=dem --q
  # Combine a subset of all the viewsheds
  # * is a wildcard for zero or more characters
  r.series -z input=`g.mlist --q type=rast pattern=tmp_los_*$i sep=,` out=total_los_$i method=sum --o --q
done
# Then combine the series 0-9 into the final LOS raster
g.region -pm rast=dem --q
r.series -z input=`g.mlist --q type=rast pattern=total_los_* sep=,` out=total_los method=sum --o --q

# Create distance to road map
echo "\nDetermining distance from roads\n"
g.region -pm rast=dem --q
v.to.rast in=road out=road use=val val=1 --o --q
r.grow.distance -m input=road distance=dist_from_road --o --q

# Use distance to road instead of viewing angle in the
#   viewshed result map
echo "\nSubstituting viewing angle for distance to road\n"
r.mapcalc "dist_los = if(total_los, dist_from_road, null())"

# Clean up, removing the component visibility rasters
echo "\nDeleting temporary files\n"
g.mremove -f type=rast pattern="tmp_los_*" --q

echo "\ngenerate_los.sh complete\n"