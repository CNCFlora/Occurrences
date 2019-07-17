

L.control.Table = L.Control.extend({

  options: {
      position: 'bottomleft',
      handler: {}
  },

  containers:{},

  createTable: function(rel) {
    var table = L.DomUtil.create('table');
    table.setAttribute("rel",rel);
    var tbody = L.DomUtil.create('tbody');
    var thead = L.DomUtil.create('thead');
    table.appendChild(thead);
    table.appendChild(tbody);
    return table;
  },

  addTable: function(table,title) {
    var container = L.DomUtil.create('div','map-table-container');
    this.tables.appendChild(container);
    container.appendChild(table);

    var option = L.DomUtil.create('option');
    option.value=table.getAttribute('rel');
    option.innerHTML=title;
    this.switcher.appendChild(option);

    container.style.display='none';

    this.containers[table.getAttribute('rel')] = container;

    return container;
  },

  linkTable: function(table,fields,layers) {
    var that=this;
    layers.eachLayer(function(layer){
      if(table) {
        that.addToTable(layer,fields,table);
      }
      layer.bindPopup(that.createPopup(layer));
    });
  },

  createPopup: function(layer) {
    var feat = layer.feature;
    var container = document.createElement('div');
    var table = document.createElement('table');
    for(var k in feat.properties) {
      if(typeof feat.properties[k] == 'undefined' || feat.properties[k] == null) feat.properties[k] = "";
      var v  = feat.properties[k];

      var tr = document.createElement('tr');

      var col = document.createElement('th');
      col.innerHTML = k;

      var val = document.createElement('td');
      if(v[0] == "/") {
        val.innerHTML = '<a href="'+v+'">'+v+'</a>';
      } else {
        val.innerHTML = v;
      }

      tr.appendChild(col);
      tr.appendChild(val);

      table.appendChild(tr);
    }
    container.appendChild(table);
    return container;
  },

  createHeaders: function(table,fields) {
    var tr = document.createElement('tr');

    for(var i=0;i<fields.length;i++){
      var field = fields[i];
      var th = document.createElement('th')

      var label = document.createElement('span');
      label.innerHTML = field;
      th.appendChild(label);

      var input = document.createElement('input');
      input.type='text';
      input.name=field;
      th.appendChild(input);

      input.onchange=function(evt){
        var filters=[];
        var inputs = table.querySelectorAll('thead input');
        for(var i=0;i<inputs.length;i++) {
          if(inputs[i].value.length >= 1) {
            filters.push([inputs[i].name,inputs[i].value]);
          }
        }

        var trs = table.querySelectorAll('tbody>tr');
        for(var i=0;i<trs.length;i++) {
          var ok =true;

          var tds=trs[i].querySelectorAll('td');
          for(var t=0;t<tds.length;t++) {
            var td_f=tds[t].dataset.field;
            var td_v=tds[t].dataset.value;

            for(var f=0;f<filters.length;f++) {
              if(td_f==filters[f][0]) {
                if(td_v.indexOf(filters[f][1]) < 0) {
                  ok=false;
                }
              }
            }
          }
          if(ok) {
            trs[i].style.display='table-row';
          } else {
            trs[i].style.display='none';
          }
        }
      };

      tr.appendChild(th);
    }

    table.querySelector('thead').appendChild(tr);
  },

  addToTable: function(properties,fields,table,fun) {
    var line ={};

    var tr = document.createElement('tr');
    for(var f=0;f<fields.length;f++){
      var td  = document.createElement('td');
      var key = fields[f];
      var value =""
      if(typeof properties[key] == "string" || typeof properties[key] == "number") {
        value = ""+ properties[key];
      }
      td.innerHTML =value;
      td.dataset.field=key;
      td.dataset.value=value;

      td.onclick = function(evt) {
        fun(evt,line);
      };

      tr.appendChild(td);
    }

    var index = table.querySelectorAll("tr").length;

    function focus() {
      var all = table.querySelectorAll("tr");
      var size =0;
      for(var i=0;i<index - 1;i++) {
        size += all[i].clientHeight;
        all[i].setAttribute("class","");
      }
      tr.setAttribute("class","focus");
      table.parentNode.scrollTop = size;
    };

    table.querySelector("tbody").appendChild(tr);

    line.focus = focus;
    line.tr =tr;
    return line;
  },

  onAdd: function(map) {
    this._map=map;

    L.DomEvent.addListener(this.control, 'mouseover',function(){
      map.dragging.disable();
      map.doubleClickZoom.disable();
      map.scrollWheelZoom.disable();
    },this);

    L.DomEvent.addListener(this.control, 'mouseout',function(){
      map.dragging.enable();
      map.doubleClickZoom.enable();
      map.scrollWheelZoom.enable();
    },this);

    return this.control;
  },

  initialize: function(){
    var that = this;

    var control = L.DomUtil.create('div','leaflet-control leaflet-table-container');
    var inner = L.DomUtil.create('div');

    var tables = L.DomUtil.create('div','leaflet-tables-container');
    this.tables = tables;

    var switcher = L.DomUtil.create('select','leaflet-table-select');
    switcher.addEventListener('change',function(evt){
        var curr = evt.target[ evt.target.selectedIndex ].value;
        for(var rel in that.containers) {
          var container = that.containers[rel];
          if(rel==curr && container.style.display != 'block') {
            container.style.display='block';
          } else {
            container.style.display='none';
          }
        }
    },false);
    this.switcher=switcher;

    var option = L.DomUtil.create('option');
    option.value='none';
    option.innerHTML='Tables';
    switcher.appendChild(option);

    control.appendChild(inner);
    inner.appendChild(switcher);
    inner.appendChild(tables);

    control.onmousedown = control.ondblclick = L.DomEvent.stopPropagation;

    this.control=control;
  }
});

