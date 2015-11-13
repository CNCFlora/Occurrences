
function table() {

  var headers =[
    {name:"occurrenceID",editor:false, width: 600},
    {name:"recordedBy",editor:false, width: 150},
    {name:"recordNumber",editor:false, width: 150},
    {name:"collectionCode",editor:false, width: 350},
    {name:"catalogNumber",editor:false, width: 150},
    {name:"year",editor:false, width: 50},
    {name:"stateProvince",editor:false, width: 300},
    {name:"municipality",editor: false, width: 300},
    {name:"locality",editor: false, width: 350},
    {name:"remarks",editor:false, width: 400},
    {name:"comments",editor:false, width: 400},
    {name:"decimalLatitude",editor:"text", width: 200},
    {name:"decimalLongitude",editor:"text", width: 200},
    {name:"georeferenceVerificationStatus",editor:'select',selectOptions: ['','ok','nok','uncertain-locality']},
    {name:"georeferenceProtocol",editor:'select',selectOptions: ['','coletor','sig','google earth']},
    {name:"coordinateUncertaintyInMeters",editor:'text'}
  ];

  var fields= headers.map(function(h){return h.name});

  var data = occurrences.map(function(occ){
    var row =[];
    for(var f=0;f<fields.length;f++){
      row.push(occ[fields[f]]);
    }
    return row;
  });

  var container=document.getElementById('table');

  var renderer = function(instance, td, row, col, prop, value, cellProperties) {
      Handsontable.renderers.TextRenderer.apply(this, arguments);
      var geo = occurrences[row]['georeferenceVerificationStatus'];
      if(typeof geo != "string") {
        td.style.color = 'blue';
      } else if(geo == 'ok') {
        td.style.color = 'green';
      } else if(geo == 'nok') {
        td.style.color = 'gray';
      } else {
        td.style.color = 'blue';
      }
  }

  var hot = new Handsontable(container,{
    data:data,
    colHeaders: fields,
    columns: headers,
    rowHeaders:true,
    columnSorting: true,
    undo: true,
    allowInsertColumn:false,
    allowInsertRow:false,
    allowRemoveColumn:false,
    allowRemoveRow:false,
    manualColumnResize: true,
    cells: function(row,col,prop){
      return { renderer : renderer };
    }
  });

  var changed = function(changes,source) {
    if(source != 'edit') return;
    $("#saving").show();
    var todo=changes.length;
    var done=0;
    for(var i=0;i<todo;i++) {
      var row=changes[i][0];
      var col=changes[i][1];
      var old=changes[i][2];
      var val=changes[i][3];
      var obj=occurrences[row];
      var fld=fields[col];
      var id =obj.occurrenceID;
      var url=base+'/'+db+'/occurrence/'+encodeURIComponent(id)+'/data/'+fld;
      var dat='value='+encodeURIComponent(val);
      $.post(url,dat,function(a,b){
        done++;
        if(done == todo) {
          $("#saving").hide();
        }
      });
    }
  };

  Handsontable.hooks.add("afterChange",changed,hot);
}

