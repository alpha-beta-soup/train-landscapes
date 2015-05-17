#!/bin/bash

LINE_SHP='../data/roads.shp' # Roads shapefile
R_DEM='../data/nidemreproj' # Elevation DEM
PTS_FILE="../data/road_points_coords.csv" # An intermediate output of this script; coordinates of LINE_SHP
R_RES=25 # The resolution of the DEM (metres)
DIST_PTS=25 # Maximum distance between observer points: ideally the resolution of the DEM
MAX_VIS_DIST=30000 # Maximum distance visible
ELEV=1.2 # Metres above the ground that the observer stands (note, try include the vehicle, too)
OUTFILE="dist_los_car" # Name of final output raster
# Default north, south, etc. values, set with respect to the chosen projection
mostNorth=0
mostSouth=9999999
mostEast=0
mostWest=9999999

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

# Some functions to allow comparison of floating point numbers
float_test() {
    # Return status code of a comparison
     echo | awk 'END { exit ( !( '"$1"')); }'
}
return_larger() {
    # Return larger of two numbers (two float inputs)
    float_test "$1 > $2" && larger=$1
    float_test "$1 < $2" && larger=$2
    float_test "$1 == $2" && larger=$1 # They're equal
    echo $larger
}
return_smaller() {
    # Return small of two numbers (two float inputs)
    float_test "$1 > $2" && smaller=$2
    float_test "$1 < $2" && smaller=$1
    float_test "$1 == $2" && smaller=$1 # They're equal
    echo $smaller
}

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
  
  # Update mostNorth etc.
  # We collect the most extreme values for the extent so we can combine
  #   the component rasters later more efficiently (r.series will only be as big
  #   as it needs to be, and no bigger, so probably smaller than the input DEM)
  mostNorth=$(return_larger $mostNorth $N)
  mostSouth=$(return_smaller $mostSouth $S)
  mostEast=$(return_larger $mostEast $E)
  mostWest=$(return_smaller $mostWest $W)
  
  # Does not overwrite, so SIGINT (Ctrl+C) can be used to interrupt a
  #   long-running process, to be resumed later
  #   (keep parameters constant between runs)
  r.viewshed -crb input=dem output=tmp_los_${COUNTER} coordinates=$line obs_elev=$ELEV max_dist=$MAX_VIS_DIST memory=2000 --q
  COUNTER=$((COUNTER+1))
  
done < $PTS_FILE

# Combine results in a single map 
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
# Set computational region to largest neccessary extent
g.region -m n=$mostNorth s=$mostSouth e=$mostEast w=$mostWest --q

echo $mostNorth
echo $mostSouth
echo $mostEast
echo $mostWest

echo "\nCombining component viewsheds\n"
# Loops because otherwise can easily exceed default hard limit of number of
#  rasters that can be open at once (1024)
# r.series -z flag, new in grass70, "don't keep files open"

# TODO won't this ignore tmp_los_1 >> tmp_los_9?

##for i in `seq 0 99`;
for i in `seq 66 99`;
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
  echo "\nComponent r.series: r.series -z input=g.mlist --q type=rast pattern=$PATT sep=, out=$OUT method=sum --o --q\n"
  r.series -z input=`g.mlist --q type=rast pattern=$PATT sep=,` out=$OUT method=sum --o --q 
done

# Then combine the series 00-99 into the final LOS raster
echo "\nFinal r.series: r.series -z input=g.mlist --q type=rast pattern=total_los_* sep=, out=total_los method=sum --o --q\n"
r.series -z input=`g.mlist --q type=rast pattern=total_los_* sep=,` out=total_los method=sum --o --q

# Create distance to road map
echo "\nDetermining distance from roads\n"
v.to.rast in=road out=road use=val val=1 --o --q
r.grow.distance -m input=road distance=dist_from_road --o --q

# Use distance to road instead of viewing angle in the
#   viewshed result map
echo "\nSubstituting viewing angle for distance to road\n"
g.remove $OUTFILE
r.mapcalc "$OUTFILE = if(total_los, dist_from_road, null())"

# Clean up, removing the component visibility rasters, only after outputs have been written
echo "\nDeleting temporary files\n"
g.mremove -f type=rast pattern="tmp_los_*" --q

echo "\ngenerate_los.sh complete\n"