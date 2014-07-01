
$(function(){

    Connect({
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

    $("select[name=status]").change(function(){
        var val = $(this).val();
        var ctx = $(this).parent().parent();
        if(val == 'valid') {
            $("*[rel=valid]",ctx).show();
            $("*[rel=invalid]",ctx).hide();
        } else if(val =='invalid'){
            $("*[rel=valid]",ctx).hide();
            $("*[rel=invalid]",ctx).show();
        } else {
            $("select[name=reason]").val("N/A");
            $("*[rel=valid]",ctx).hide();
            $("*[rel=invalid]",ctx).hide();
            $("*[rel=both]",ctx).hide();
            $("select[name=reason] option:first").show();
        }
    });

});

