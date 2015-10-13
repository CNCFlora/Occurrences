
function table() {

  var headers =[
    {name:"occurrenceID",type:"string",editor:'DisabledEditor'},
    {name:"recordedBy",type:"string",editor:'DisabledEditor'},
    {name:"recordNumber",type:"string",editor:'DisabledEditor'},
    {name:"collectionCode",type:"string",editor:'DisabledEditor'},
    {name:"catalogNumber",type:"string",editor:'DisabledEditor'},
    {name:"year",type:"string",editor:'DisabledEditor'},
    {name:"stateProvince",type:"string",editor:'DisabledEditor'},
    {name:"municipality",type:"string",editor: 'DisabledEditor'},
    {name:"locality",type:"string",editor: 'DisabledEditor'},
    {name:"remarks",type:"string",editor:'DisabledEditor'},
    {name:"comments",type:"string",editor:'DisabledEditor'},
    {name:"decimalLatitude",type:"float"},
    {name:"decimalLongitude",type:"float",},
    {name:"georeferenceVerificationStatus",type:"string",editor:'SelectEditor',editorProps:{values: ['','ok','nok','uncertain-locality'] }},
    {name:"georeferenceProtocol",type:"string",editor:'SelectEditor',editorProps:{values: ['','coletor','sig'] }},
    {name:"coordinateUncertaintyInMeters",type:"string"}
  ];

  var rows=occurrences;

  var rows=occurrences;

  var opts={
    sortable: true
  };

  var grid= new Supagrid({
    fields: headers.map(function(h){return h.name}),
    data: occurrences,
    element: document.getElementById('table'),
    on: {
      change: function(obj,field,value){
        $("#saving").show();
        $.post(base+'/'+db+'/occurrence/'+encodeURIComponent(obj.occurrenceID)+'/data/'+field,'value='+encodeURIComponent(value),function(a,b){
          $("#saving").hide();
        });
      }
    }
  });

}

