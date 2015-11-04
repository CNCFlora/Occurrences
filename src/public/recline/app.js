var _data;
var fields=[];

jQuery(function($) {

    var from = getQueryVariable('from');
    var to = getQueryVariable('to');
    var dFields = getQueryVariable('fields');

    if(from) {
        if(from.indexOf("?") < 0) {
            from+="?";
        }
        var url = from+"&callback=?";
        $.getJSON(url.replace("&quot;","\""),function(records){
            if(records.length <= 0) alert("no data");

            if(dFields) {
                fields = dFields.split(','); 
            } else {
                for(var c in records) {
                    for(var i in records[c]) {
                        if(typeof records[c][i] != 'object') {
                            var got=false;
                            for(var o in fields) {
                                if(fields[o] == i) {
                                    got=true;
                                }
                            }
                            if(!got) fields.push(i);
                        }
                    }
                }
            }

            var columns = fields.map(function(f){
                return {
                    id: /^[a-zA-Z0-9_]+/.exec(f)[0],
                    width: 300,
                    label: /[a-zA-Z0-9_]+$/.exec(f)[0]
                }
            });

            createExplorer(new recline.Model.Dataset({
                records: records,
                fields: columns
            })); 

            if(to) {
                var url = to;
                var bt = $("<buttton>Finish and Save</button>");
                bt.on('click',function(){
                    var data = JSON.stringify(_data.records.models.map(function(a){return a.attributes;})).replace(/'/g,"`");
                    var form = $('<form method="POST" action="'+url+'"></form>');
                    form.append('<input name="data" type="hidden" value=\''+data+'\'" />');
                    $("body").append(form);
                    form.submit();
                });
                bt.addClass('btn');
                $(".menu-right").append(bt);
            }

            var downLink = $("<a href='http://cncflora.jbrj.gov.br/dwc_services/api/v1/convert?from=json&to=csv&url="+encodeURIComponent(from)+"' download='data.csv'>Download as CSV</a>");
            $(".container").append(downLink);

            $(".menu-right a").remove();

        });

    }
});


var createExplorer = function(dataset) {

    _data = dataset;

    var $el = $('<div />');
    $el.appendTo($('.data-explorer-here'));

    var views = [
        {
            id: 'grid',
            label: 'Grid',
            view: new recline.View.SlickGrid({
                model: dataset,
                state: {
                    gridOptions: {
                        editable: true,
                        //enabledAddRow: true,
                        //enabledDelRow: true,
                        autoEdit: false,
                        enableCellNavigation: true
                    }
                }
            })
        },
        {
            id: 'map',
            label: 'Map',
            view: new recline.View.Map({
                model: dataset
            })
        }
        /*
        {
            id: 'graph',
            label: 'Graph',
            view: new recline.View.Graph({
                model: dataset
            })
        }
        */
    ];

    new recline.View.MultiView({
        model: dataset,
        el: $el,
        views: views
    });

}

function getQueryVariable(variable) {
    var query = window.location.search.substring(1);
    var vars = query.split('&');
    for (var i = 0; i < vars.length; i++) {
        var pair = vars[i].split('=');
        if (decodeURIComponent(pair[0]) == variable) {
            return decodeURIComponent(pair[1]);
        }
    }
}

