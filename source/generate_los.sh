#!/bin/bash

usage() {
   cat << EOF
Usage: generate_los.sh [-train | -road]

-train    perform the viewshed analysis for the train journey
-road     perform the viewshed analysis for the road journey
EOF
   exit 1
}

# Number of arguments
# If there is more or less than one, do usage()
if [ $# -ne 1 ]; then
   usage;
fi

if [ "$1" != "-train" ] && [ "$1" != "-road" ]; then
  usage;
fi

if [ $1 = "-road" ]
then
    LINE_SHP='../data/road/roads.shp' # Roads shapefile
    PTS_FILE="../data/road/road_points_coords.csv"
    # ^ An intermediate output of this script; coordinates of LINE_SHP
    ELEV=1.2 # Metres above the ground that the observer stands
    # ^ just a guess (note, try include the vehicle, too)
    OUTFILE="dist_los_car" # Name of final output raster
elif [ $1 = "-train" ]
then
    # We live in a post-shapefile world, baby!
    LINE_SHP='../data/train/nz-railway-centrelines-topo-150k.gpkg' # Rail geopackage
    PTS_FILE="../data/train/rail_points_coords.csv"
    # ^ An intermediate output of this script; coordinates of LINE_SHP
    ELEV=2.5 # Metres above the ground that the observer stands
    # ^ just a guess (note, try include the vehicle, too)
    OUTFILE="dist_los_rail" # Name of final output raster
else
    usage; # shouldn't need this
fi

R_DEM='../data/hillshade/nidemreproj' # Elevation DEM
R_RES=25 # The resolution of the DEM (metres)
DIST_PTS=25 # Ideally the resolution of the DEM
MAX_VIS_DIST=30000 # Maximum distance visible

# r.los takes a long time, and the manual says to keep the number of rows and columns
#   "under 1000". Here we adjust MAX_VIS_DIST by considering the resolution of
#   the raster (R_RES), so that there is a maximum of 1000 rows and columns
POS_VIS_DIST=$(echo "$R_RES * 1000 / 2" | bc -l) # The maximum possible vis dist to use and still have 1000 rows and cols
if [ 1 -eq `echo "$POS_VIS_DIST < $MAX_VIS_DIST" | bc` ]
then
  # If the maximum distance r.los can sustain exceeds the user-selected value, override it
  echo "\nThe MAX_VIS_DIST parameter has been changed from $MAX_VIS_DIST to $POS_VIS_DIST for performance reasons.\n"
  MAX_VIS_DIST=$POS_VIS_DIST
fi

# Load shapefile into GRASS
v.in.ogr dsn=$LINE_SHP output=line_feature --o --v

# Load elevation raster into GRASS and set it as the computational region
r.in.gdal --o input=$R_DEM output=dem --verbose

# Sample points along line
v.to.points -ivt in=line_feature out=line_feature_points dmax=$DIST_PTS --o --q

# Put point coordinates in text file
v.out.ascii -r in=line_feature_points fs=, --quiet | awk -F "\"*,\"*" '{print $1","$2}' > $PTS_FILE

NPTS=`cat $PTS_FILE | wc -l`

# Solution using r.los (r.viewshed in GRASS 7.0)
# ==============================================

echo -n "\nComputing viewsheds\n"

COUNTER=0
while read -r line
  do

  PCT_FLOAT=$(echo "100*$((COUNTER+1))/$NPTS" | bc -l)
  PCT=`printf "%0.1f\n" $PCT_FLOAT`

  echo -ne "Processing $NPTS viewshed instances: \t $PCT % ($COUNTER/$NPTS) \r"

  # Set the region to a smaller subset around the current observer point
  #   to speed processing
  x=$(echo $line | cut -f1 -d,)
  y=$(echo $line | cut -f2 -d,)
  W=$(echo "$x-$MAX_VIS_DIST" | bc -l)
  E=$(echo "$x+$MAX_VIS_DIST" | bc -l)
  N=$(echo "$y+$MAX_VIS_DIST" | bc -l)
  S=$(echo "$y-$MAX_VIS_DIST" | bc -l)
  g.region n=$N s=$S e=$E w=$W

  # Does not overwrite, so SIGINT (Ctrl+C) can be used to interrupt a
  #  long-running process, to be resumed later
  #  (keep parameters constant between runs)
  r.los input=dem output=tmp_los_${COUNTER} coordinate=$line obs_elev=$ELEV max_dist=$MAX_VIS_DIST --v
  COUNTER=$((COUNTER+1))

done < $PTS_FILE

# Set computational region to full extent
g.region -pm rast=dem --verbose

# Combine results in a single map
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
echo "\nCombining component viewsheds\n"
# Loops because otherwise can easily exceed default hard limit of number of
#  rasters that can be open at once (1024)
for i in `seq 0 99`;
do
  # Combine a subset of all the viewsheds
  # * is a wildcard for zero or more characters
  if [ $i -le 9 ] # If i <= 9
  then # append a 0 to the start of $i
    PATT=tmp_los_*0$i
    OUT=total_los_0$i
  else # don't modify the pattern of $i
    PATT=tmp_los_*$i
    OUT=total_los_$i
  fi
  r.series in=`g.mlist --q type=rast pattern=$PATT sep=,` out=$OUT method=sum --o --q
done

# Then combine the series 00-99 into the final LOS raster
g.region -pm rast=dem --q
r.series in=`g.mlist --q type=rast pattern=total_los_* sep=,` out=total_los method=sum --o --q

# Create distance to line_feature map
echo "\nDetermining distance from features\n"
v.to.rast in=line_feature out=line_feature use=val val=1 --o --q
r.grow.distance -m input=line_feature distance=dist_from_line_feature --o --q

# Use distance to line_feature instead of sum of times seen in the result map
echo "\nSubstituting number of times seen for distance to cell from line\n"
r.mapcalc "$OUTFILE = if(total_los, dist_from_line_feature, null())"  --o --v

# Write output (as geotiff)
r.out.gdal input=$OUTFILE output=../data/output/$OUTFILE.tif format=GTiff --o --v

# Clean up, removing the component visibility rasters, only after outputs have been written
echo "\nDeleting temporary files\n"
g.mremove -f "tmp_los_*" --q
g.mremove -f "total_los_*" --q

echo "\ngenerate_los.sh complete\n"
