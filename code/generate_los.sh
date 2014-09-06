#/bin/bash
# Grass 6.4

# Load shapefile into GRASS
v.in.ogr dsn=roads.shp output=road -o

PTS_FILE="./road_points_coords.csv"
DIST_PTS=25 # Ideally the resolution of the DEM
MAX_VIS_DIST=30000 # Maximum distance visible

# Sample points along line
v.to.points -nvit in=roadsg out=roads_points dmax=$DIST_PTS --o --q

# Put point coordinates in text file
v.out.ascii -r in=roads_points fs=, --quiet | awk -F "\"*,\"*" '{print $1","$2}' > $PTS_FILE

NPTS=`cat $PTS_FILE | wc -l`

# Solution using r.viewshed
# =========================

echo -ne "\nComputing viewsheds\n"

COUNTER=0
while read -r line
  do
  
  PCT_FLOAT=$(echo "100*$((COUNTER+1))/$NPTS" | bc -l)
  PCT=`printf "%0.1f\n" $PCT_FLOAT` 

  echo -ne "Processing $NPTS viewshed instances: \t $PCT % \r" 
  
  r.los -c input=dem output=los_${COUNTER} coordinate=$line max_dist=$MAX_VIS_DIST --o --q
  COUNTER=$((COUNTER+1))
  
done < $PTS_FILE

echo "\n"

# Combine results in a single map 
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
r.series in=`g.mlist --q type=rast pat=los_* sep=,` out=total_los method=sum --o

# Create distance to road map
v.to.rast in=road out=road use=val val=1 --o
r.grow.distance -m input=road distance=dist_from_road --o --q

# Use distance to road instead of viewing angle in the
# viewshed result map 
r.mapcalc "dist_los = if(total_los, dist_from_road, null())" --o --q
