#/bin/bash

PTS_FILE="./rail_points_coords.csv"
DIST_PTS=100
MAX_VIS_DIST=30000

# Sample points along line
v.to.points in=rail out=rail_points dmax=$DIST_PTS --o --q

# Put point coordinates in text file
v.out.ascii --q in=rail_points sep=, | awk -F "\"*,\"*" '{print $1","$2}' > $PTS_FILE

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
  
  r.viewshed -crb in=dem out=los_${COUNTER} coord=$line max_dist=$MAX_VIS_DIST memory=1500 --o --q
  COUNTER=$((COUNTER+1))
  
done < $PTS_FILE

echo "\n"

# Combine results in a single map 
#   (aggregation method doesn't matter as we use
#   this as a boolean mask)
r.series in=`g.mlist --q type=rast pat=los_* sep=,` out=total_los method=sum --o

# Create distance to railway map
v.to.rast in=rail out=rail use=val val=1 --o
r.grow.distance -m input=rail distance=dist_from_rail --o --q

# Use distance to railway instead of viewing angle in the
# viewshed result map 
r.mapcalc "dist_los = if(total_los, dist_from_rail, null())" --o --q
