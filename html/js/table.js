
function table() {

  var headers =[];
  var got_header={};
  var rows=[];

  for(var i=0;i<occurrences.length;i++){
    for(var k in occurrences[i]) {
      if(typeof got_header[k] == 'undefined') {
        headers.push(k);
        got_header[k]=true;
      }
    }
  }
  for(var i=0;i<occurrences.length;i++){
    var row=[];
    for(var k in headers){
      row.push(occurrences[i][headers[k]]);
    }
    rows.push(row);
  }

  var data = {
    Head: [ headers ],
    Body: rows
  };
  console.log(data);

  var grid = new Grid("grid",{
      srcType: 'json',
      srcData: data,
       allowGridResize : true, 
         allowColumnResize : true, 
           allowClientSideSorting : true, 
             allowSelections : true, 
               allowMultipleSelections : true, 
                 showSelectionColumn : true, 
                   fixedCols : 1
  });
}

