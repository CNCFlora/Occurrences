
$(function(){

  Connect({
    onlogin: function(nuser) {
      if(logged && nuser.email == user.email) return;
      $.post(base+'/login','user='+JSON.stringify(nuser),function(){
        location.reload();
      });
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

  $(".sig-form").each(function(i,e){
    var form=e;
    if(form.getAttribute("rel")!='ok') {
      form.onsubmit=function() { return false; };
      var fields = form.querySelectorAll("input,textarea,select");
      for(var i=0;i<fields.length;i++) {
        fields[i].setAttribute('readonly','readonly');
      }
    }
  });
  $(".analysis-form").each(function(i,e){
    var form=e;
    if(form.getAttribute("rel")!='ok') {
      form.onsubmit=function() { return false; };
      var fields = form.querySelectorAll("input,textarea,select");
      for(var i=0;i<fields.length;i++) {
        fields[i].setAttribute('readonly','readonly');
      }
    }
  });

  $(".validation-form").each(function(i,e){
    var form=e;
    if(form.getAttribute("rel")!='ok') {
      form.onsubmit=function() { return false; };
      var fields = form.querySelectorAll("input,textarea,select");
      for(var i=0;i<fields.length;i++) {
        fields[i].setAttribute('readonly','readonly');
      }
    }

    form = $(e);
    var taxonomy = $("input[name=taxonomy]",form);
    var comments = $("textarea[name=comment]",form);
    form.submit(function(){
        var taxonomy_sel = $("input[name=taxonomy]:checked",form);
        var len = $("input:checked",form).length;
        if(taxonomy_sel.val() == 'valid' && len != 6) {
          alert("É preciso responder todas as perguntas");
          return false;
        } else {
          return true;
        }
    });

    var dup = $("input[name=duplicated]:checked",form);
    if(dup.length ==0){
      //$("input[name=duplicated][value=no]",form).prop("checked",true);
    }

    taxonomy.change(function(){
      var taxonomy_sel = $("input[name=taxonomy]:checked",form);
      if(taxonomy_sel.val() == "invalid") {
          $(".form-group",form).hide();
          taxonomy.parent().parent().show();
          comments.parent().show();
      } else {
          $(".form-group",form).show();
      }
    });
    var taxonomy_sel = $("input[name=taxonomy]:checked",form);
    if(taxonomy_sel.val() =='invalid') {
       $(".form-group",form).hide();
       taxonomy.parent().parent().show();
       comments.parent().show();
    }
  });

  $(".insert").submit(function(){
      return confirm(strings['confirm-insert']);
  });

});

