var map = function() {

    var map = L.map('map',{crs:L.CRS.EPSG3857}).setView([-15.79889,-47.866667],4);

    var land = L.tileLayer('http://{s}.tile3.opencyclemap.org/landscape/{z}/{x}/{y}.png')//.addTo(map);
    var ocm = L.tileLayer('http://{s}.tile.opencyclemap.org/cycle/{z}/{x}/{y}.png').addTo(map);
    var osm = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png')//.addTo(map);

    var markersOk = new L.MarkerClusterGroup(); // clustered valid points
    var pointsOk  = new L.layerGroup(); // valid points

    var markersNok = new L.MarkerClusterGroup(); // clustered invalid points
    var pointsNok  = new L.layerGroup(); // invalid points

    var markersUnk = new L.MarkerClusterGroup(); // clustered unkown points
    var pointsUnk  = new L.layerGroup(); // unkown points

    var points  = {};

    var calc = [];

    for(var i in occurrences) {
        var feature = occurrences[i];

        if(!feature.decimalLatitude || !feature.decimalLongitude) continue;
        if(feature.decimalLatitude == 0.0 || feature.decimalLongitude == 0.0) continue;

        var marker = L.marker(new L.LatLng(feature.decimalLatitude,feature.decimalLongitude));
        marker.bindPopup(document.getElementById("occ-"+feature.occurrenceID+"-unit").innerHTML);

        if(typeof feature.validation == 'object') {
            if(typeof feature.validation.status == 'string') {
                if(feature.validation.status == 'valid') {
                    markersOk.addLayer(marker);
                    pointsOk.addLayer(marker);
                    calc.push(feature);
                } else if(feature.validation.status == 'invalid') {
                    markersNok.addLayer(marker);
                    pointsNok.addLayer(marker);
                } else {
                    markersUnk.addLayer(marker);
                    pointsUnk.addLayer(marker);
                    calc.push(feature);
                }
            } else {
                markersUnk.addLayer(marker);
                pointsUnk.addLayer(marker);
                calc.push(feature);
            }
        } else {
            markersUnk.addLayer(marker);
            pointsUnk.addLayer(marker);
            calc.push(feature);
        }

        points[feature.occurrenceID] = marker;
    }

    map.addLayer(markersOk);
    map.addLayer(markersNok);
    map.addLayer(markersUnk);

    var base = {
        Landscape: land,
        OpenCycleMap: ocm,
        OpenStreetMap: osm
    };

    var layers = {
        'Valid points': pointsOk,
        'Valid points clustered': markersOk,
        'Non-valid points': pointsNok,
        'Non-valid points clustered': markersNok,
        'Non-validated points': pointsUnk,
        'Non-validated points clustered': markersUnk
    };

    if(typeof eoo == 'object') {
        var eool = L.geoJson(eoo).addTo(map);
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

    $(".to-map").click(function(evt){ 
        // zoom in and open point in map
        var id = $(evt.target).attr("rel");
        map.setView(points[id]._latlng,10)
        setTimeout(function(){
            location.hash="map";
            points[id].openPopup();
        },250);
        location.hash="";
    });

};

