
$(function(){

    Connect({
        context: context,
        onlogin: function(user) {
            if(!logged) {
                $.post(base+'/login','user='+JSON.stringify(user),function(){
                    location.reload();
                });
            }
        },
        onlogout: function(nothing){
            if(logged) {
                $.post(base+'/logout',nothing,function(){
                    location.reload();
                });
            }
        }
    });

    $("#login a").click(function(){ Connect.login(); });
    $("#logout a").click(function(){ Connect.logout(); });

    if(typeof map == 'function') {
        map();
    }

    $(".glyphicon-question-sign,.glyphicon-remove-circle,.glyphicon-ok-circle").tooltip({});

    $(".validation-form").each(function(i,e){
        var form = $(e);
        var taxonomy = $("input[name=taxonomy]",form);
        var georeference = $("input[name=georeference]",form);
        var comments = $("textarea[name=comment]",form);
        form.submit(function(){
            var taxonomy_sel = $("input[name=taxonomy]:checked",form);
            var georeference_sel = $("input[name=georeference]:checked",form);
            var presence_sel = $("input[name=presence]:checked",form);
            var duplicated_sel = $("input[name=duplicated]:checked",form);
            var georeference_sel = $("input[name=georeference]:checked",form);
            if(taxonomy_sel.val()=="invalid" || georeference_sel.val() == "invalid" ||
                presence_sel.val() == 'absent' || duplicated_sel.val() == 'yes') {
                if(comments.val().length <= 3) {
                    alert("Necessária justificativa.");
                    return false;
                } else {
                    return true;
                }
            }else{
                 return true;
            }
        });
        $(".form-group",form).hide();
        taxonomy.parent().parent().show();
        comments.parent().show();
        function changedv()  {
            var taxonomy_sel = $("input[name=taxonomy]:checked",form);
            if(taxonomy_sel.val() == "invalid") {
                $(".form-group",form).hide();
                taxonomy.parent().parent().show();
                comments.parent().show();
            }  else {
                $(".form-group",form).show();
            }
        };
        taxonomy.change(function(){
            changedv();
        });
        changedv();
    });

});

