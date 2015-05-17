// initialize the map on the "map" div with a given center and zoom
var map = L.map('map').setView([-38.6875, 176.0694], 7);

L.tileLayer('http://{s}.tiles.mapbox.com/v3/alpha-beta-soup.jhokb32m/{z}/{x}/{y}.png', {
    attribution: 'Map data &copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="http://mapbox.com">Mapbox</a>',
    maxZoom: 18
}).addTo(map);
                        
var carViewshed = '/tiles/Mapnik/{z}/{x}/{y}.png'

L.tileLayer(carViewshed, {
  attribution: 'Richard Law',
  maxZoom: 15,
  tms: true,
  isBaseLayer: false,
  opacity: 0.7,
  transparent: true
}).addTo(map);
