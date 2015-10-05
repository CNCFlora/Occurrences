
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

  var opts={
    sortable: true
  };

  var grid = $(".table").grid(rows,headers,opts);

  grid.registerEditor(BasicEditor);
  grid.registerEditor(SelectEditor);
  grid.registerEditor(DisabledEditor);

  grid.events.on('editor:save',function(data,$cell){
      var who = $cell[0].parentNode.querySelector('td:first-child').textContent;
      var field = Object.keys(data)[0];
      var value = data[field];
      console.log(who,field,value);
      $.post(base+'/'+db+'/occurrence/'+who+'/data/'+field,'value='+encodeURIComponent(value),function(a,b){
        console.log(a,b);
      });
  });

  grid.render();
}

