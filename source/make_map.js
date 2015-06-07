
var carViewshed = 'https://s3-ap-southeast-2.amazonaws.com/train-landscapes/car/{z}/{x}/{y}.png',
    trainViewshed = 'https://s3-ap-southeast-2.amazonaws.com/train-landscapes/rail/Mapnik/{z}/{x}/{y}.png',
    southWest = [-41.722,171.748],
    northEast = [-36.441,179.124],
    bounds = [southWest, northEast],
    attribution = 'Richard Law | \
    Pierre Roudier | \
    <a href="http://maps.scinfo.org.nz/">Landcare Research</a> <a href="http://creativecommons.org/licenses/by/3.0/nz/">CC BY 3.0 NZ</a> | \
    <a href="https://koordinates.com/layer/40-nz-road-centrelines-topo-150k/">LINZ</a> <a href="http://creativecommons.org/licenses/by/3.0/nz/">CC BY 3.0 NZ</a> | \
    <a href="http://grass.osgeo.org/">GRASS GIS</a>',
    global_min_zoom = 7,
    global_max_zoom = 13;

var map = new L.Map('map');
map.setView([-38.6875, 176.0694], 7); //centre and zoom of map, initially
map.setMaxBounds(bounds);
map.options.minZoom = global_min_zoom;
map.options.maxZoom = global_max_zoom;


var car = L.tileLayer(carViewshed, {
  attribution: attribution,
  bounds: bounds,
  minZoom: global_min_zoom,
  maxZoom: global_max_zoom,
  tms: true,
  isBaseLayer: true,
  //opacity: 0.7,
  //transparent: true
}).addTo(map); //default layer, so add to map

var train = L.tileLayer(trainViewshed, {
  attribution: attribution,
  bounds: bounds,
  minZoom: global_min_zoom,
  maxZoom: global_max_zoom,
  tms: true,
  isBaseLayer: true,
  //opacity: 0.7,
  //transparent: true
}); //non-default layer, so don't add to map

var viewshedBasemaps = {
    "Car/bus view": car,
    "Overlander view": train
};

L.control.layers(viewshedBasemaps).addTo(map); // Add the layer control to the map
