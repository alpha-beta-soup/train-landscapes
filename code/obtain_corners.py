from osgeo import gdal, osr
# Click on your layer in the TOC
alayer = qgis.utils.iface.activeLayer()
bag = gdal.Open(alayer.source())
bag_gtrn = bag.GetGeoTransform()
bag_proj = bag.GetProjectionRef()
bag_srs = osr.SpatialReference(bag_proj)
geo_srs =bag_srs.CloneGeogCS()
transform = osr.CoordinateTransformation( bag_srs, geo_srs)

bag_bbox_cells = (
    (0., 0.),
    (0, bag.RasterYSize),
    (bag.RasterXSize, bag.RasterYSize),
    (bag.RasterXSize, 0),
  )

geo_pts = []
for x, y in bag_bbox_cells:
    x2 = bag_gtrn[0] + bag_gtrn[1] * x + bag_gtrn[2] * y
    y2 = bag_gtrn[3] + bag_gtrn[4] * x + bag_gtrn[5] * y
    geo_pt = transform.TransformPoint(x2, y2)[:2]
    geo_pts.append(geo_pt)
    print x, y, '->', x2, y2, '->', geo_pt