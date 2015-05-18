
var carViewshed = '/data/tiles/Mapnik/{z}/{x}/{y}.png';
var southWest = [-41.722,171.748];
var northEast = [-36.441,179.124];
var bounds = [southWest, northEast];

var map = new L.Map('map');
map.setView([-38.6875, 176.0694], 7); //centre and zoom of map, initially
map.setMaxBounds(bounds);
map.options.minZoom = 7;
map.options.maxZoom = 13;


var car = L.tileLayer(carViewshed, {
  attribution: 'Richard Law | \
  Pierre Roudier | \
  <a href="http://maps.scinfo.org.nz/">Landcare Research</a> <a href="http://creativecommons.org/licenses/by/3.0/nz/">CC BY 3.0 NZ</a> | \
  <a href="https://koordinates.com/layer/40-nz-road-centrelines-topo-150k/">LINZ</a> <a href="http://creativecommons.org/licenses/by/3.0/nz/">CC BY 3.0 NZ</a> | \
  <a href="http://grass.osgeo.org/">GRASS GIS</a>',
  bounds: bounds,
  minZoom: 7,
  maxZoom: 13,
  tms: true,
  isBaseLayer: true,
  //opacity: 0.7,
  //transparent: true
}).addTo(map); //default layer, so add to map

var train = L.tileLayer(carViewshed, {
  attribution: 'Richard Law | \
  Pierre Roudier | \
  Landcare Research and licensed by Landcare Research for re-use under <a href="http://creativecommons.org/licenses/by/3.0/nz/">Creative Commons CC-BY New Zealand license</a> | \
  <a href="http://grass.osgeo.org/">GRASS GIS</a>',
  bounds: bounds,
  minZoom: 7,
  maxZoom: 13,
  tms: true,
  isBaseLayer: true,
  //opacity: 0.7,
  //transparent: true
}); //TODO make train tiles, too //non-default layer, so don't add to map

var viewshedBasemaps = {
    "Car/bus view": car,
    "Overlander view": train
};

L.control.layers(viewshedBasemaps).addTo(map); // Add the layer control to the map


