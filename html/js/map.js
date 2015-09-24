var map = function() {

    var map = L.map('map',{crs:L.CRS.EPSG3857}).setView([-15.79889,-47.866667],4);

    var land = L.tileLayer('http://{s}.tile3.opencyclemap.org/landscape/{z}/{x}/{y}.png')//.addTo(map);
    var ocm = L.tileLayer('http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png').addTo(map);
    var osm = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png')//.addTo(map);

    var markersUsable = new L.MarkerClusterGroup(); 
    var pointsUsable  = new L.layerGroup(); 

    var markersUnusable = new L.MarkerClusterGroup(); 
    var pointsUnusable  = new L.layerGroup();

    var markersValid = new L.MarkerClusterGroup(); // clustered valid points
    var pointsValid  = new L.layerGroup(); // valid points

    var markersInvalid = new L.MarkerClusterGroup(); // clustered invalid points
    var pointsInvalid  = new L.layerGroup(); // invalid points

    var markersUnk = new L.MarkerClusterGroup(); // clustered unkown points
    var pointsUnk  = new L.layerGroup(); // unkown points

    var points  = {};

    for(var i in occurrences) {
        var feature = occurrences[i];

        if(typeof feature.decimalLatitude == 'undefined' || typeof feature.decimalLongitude == 'undefined') continue;
        if(!feature.decimalLatitude || !feature.decimalLongitude) continue;
        if(feature.decimalLatitude == null || feature.decimalLongitude == null) continue;

        if(typeof feature.decimalLatitude == 'string') {
          feature.decimalLatitude=parseFloat(feature.decimalLatitude);
        }

        if(typeof feature.decimalLongitude == 'string') {
          feature.decimalLongitude=parseFloat(feature.decimalLongitude);
        }

        if(isNaN(feature.decimalLatitude) || isNaN(feature.decimalLongitude)) continue;
        if(feature.decimalLatitude == 0.0 || feature.decimalLongitude == 0.0) continue;

        var marker = L.marker(new L.LatLng(feature.decimalLatitude,feature.decimalLongitude));
        marker.bindPopup(makePopup(feature));

        if(feature.validation.done) {
          if(feature.valid) {
            markersValid.addLayer(marker);
            pointsValid.addLayer(marker);
          } else {
            markersInvalid.addLayer(marker);
            pointsInvalid.addLayer(marker);
          }
        } else {
          markersUnk.addLayer(marker);
          pointsUnk.addLayer(marker);
        }

        if(feature.metadata.status=='valid') {
          markersUsable.addLayer(marker);
          pointsUsable.addLayer(marker);
        } else {
          markersUnusable.addLayer(marker);
          pointsUnusable.addLayer(marker);
        }

        points[feature.occurrenceID] = marker;
    }

    map.addLayer(markersUsable);
    map.addLayer(markersUnusable);

    var base = {
        Landscape: land,
        OpenCycleMap: ocm,
        OpenStreetMap: osm
    };

    var layers = {
        'Usable points': pointsUsable,
        'Usable points clustered': markersUsable,
        'Non-Usable points': pointsUnusable,
        'Non-Usable points clustered': markersUnusable,
        'Usable points clustered': markersUsable,
        'Valid points': pointsValid,
        'Valid points clustered': markersValid,
        'Non-valid points': pointsInvalid,
        'Non-valid points clustered': markersInvalid,
        'Non-validated points': pointsUnk,
        'Non-validated points clustered': markersUnk
    };

    if(typeof eoo == 'object' && typeof eoo.geometry == 'object' && eoo.geometry != null) {
        var eool = L.geoJson(eoo.geometry).addTo(map);
        layers.EOO = eool
    }

    /*
    if(typeof aoo =='object' ) {
        var aool = L.geoJson(aoo).addTo(map);
        for(var ai in aoo.geometry.coordinates) {
            var coords = aoo.geometry.coordinates[ai];
            aool.addLayer(L.polygon(coords));
        }
        aool.addTo(map);
        layers.AOO = aool;
    }
    */

    L.control.layers(base,layers).addTo(map);
    L.control.scale().addTo(map);
    L.control.mousePosition().addTo(map);
    L.Control.measureControl().addTo(map);
};


function makePopup(props) {
  var table = document.createElement('table');
  table.setAttribute('class','table table-striped');

  for(var k in props) {

    if(k == 'id' || k== '_id' || k =='rev' ||k=='_rev') {
    } else if(typeof props[k] == 'object') {
      for(var kk in props[k]) {
        if(kk.indexOf("-") >= 1){
        }else if(typeof props[k][kk] == 'string' || typeof props[k][kk] == 'number') {
          var tr = document.createElement('tr');
          var td = document.createElement('td');
          td.innerHTML = k+'<br />'+kk;
          tr.appendChild(td);
          var td2 = document.createElement('td');
          td2.innerHTML = ""+props[k][kk];
          tr.appendChild(td2);
          table.appendChild(tr);
        }
      }
    } else if(typeof props[k] == 'string' || typeof props[k] == 'number') {
      var tr = document.createElement('tr');
      var td = document.createElement('td');
      td.innerHTML = k;
      tr.appendChild(td);
      var td2 = document.createElement('td');
      td2.innerHTML = ""+props[k];
      tr.appendChild(td2);
      table.appendChild(tr);
    } else {
      continue;
    }
  }

  return table;
};

