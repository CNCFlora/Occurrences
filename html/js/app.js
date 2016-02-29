
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

  if(typeof table == 'function') {
    table();
  }

  $(".glyphicon-question-sign,.glyphicon-info-sign,.glyphicon-remove-circle,.glyphicon-ok-circle").tooltip({});

  $(".sig-form").each(function(i,e){
    var form=e;
    if(form.getAttribute("rel")!='ok') {
      form.onsubmit=function() { return false; };
      var fields = form.querySelectorAll("input,textarea,select");
      for(var i=0;i<fields.length;i++) {
        fields[i].setAttribute('readonly','readonly');
        fields[i].setAttribute('disabled','disabled');
      }
    }
    form.onsubmit=function(){
      var data={};
      var radios=form.querySelectorAll('input[type=radio]:checked');
      for(var i=0;i<radios.length;i++) {
        data[radios[i].getAttribute('name')]=radios[i].value;
      }
      var texts=form.querySelectorAll('input[type=text],textarea');
      for(var i=0;i<texts.length;i++) {
        data[texts[i].getAttribute('name')]=texts[i].value;
      }
      var to = form.getAttribute('action');
      var datauri = "";
      for(var k in data) {
        datauri+="&"+k+'='+encodeURIComponent(data[k]);
      }
      $("#saving").show();
      $.post(to+'?raw=true',datauri,function(r){
        updateStats();
        var div = document.getElementById('occ-'+r['occurrenceID']+'-unit').querySelector('div:first-child');

        if(r['sig-ok']){
          var label = div.querySelector('.label-sig');
          label.classList.remove('label-warning');
          label.classList.remove('label-danger');
          label.classList.add('label-success');
          label.querySelector('.in-label').innerHTML=strings['sig-ok'];
        }else  {
          var label = div.querySelector('.label-sig');
          label.classList.remove('label-warning');
          label.classList.remove('label-success');
          label.classList.add('label-danger');
          label.querySelector('.in-label').innerHTML=strings['sig-nok'];
        }

        $("#saving").hide();
      });
      return false;
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
        fields[i].setAttribute('disabled','disabled');
      }
    }

    form.onsubmit=function(){
        var taxonomy_sel = $("input[name=taxonomy]:checked",$(form));
        var len = $("input:checked",$(form)).length;
        if(taxonomy_sel.val() == 'valid' && len != 6) {
          alert("É preciso responder todas as perguntas");
          return false;
        } else {
          var data={};
          var radios=form.querySelectorAll('input[type=radio]:checked');
          for(var i=0;i<radios.length;i++) {
            data[radios[i].getAttribute('name')]=radios[i].value;
          }
          data['remarks']=form.querySelector('textarea').value;
          var to = form.getAttribute('action');
          var datauri = "";
          for(var k in data) {
            datauri+="&"+k+'='+encodeURIComponent(data[k]);
          }

          $("#saving").show();
          $.post(to+'?raw=true',datauri,function(r){
            updateStats();
            var div = document.getElementById('occ-'+r['occurrenceID']+'-unit').querySelector('div:first-child');
            var classes=div.classList;

            if(r.valid){
              classes.remove('not-validated');
              classes.remove('invalid');
              classes.add('valid');

              var label = div.querySelector('.label-valid');
              label.classList.remove('label-warning');
              label.classList.remove('label-danger');
              label.classList.add('label-success');
              label.querySelector('span').classList.remove('glyphicon-question-sign');
              label.querySelector('span').classList.remove('glyphicon-remove-sign');
              label.querySelector('span').classList.add('glyphicon-ok-sign');
              label.querySelector('.in-label').innerHTML=strings['valid'];
            }else  {
              classes.remove('not-validated');
              classes.remove('valid');
              classes.add('invalid');
              var label = div.querySelector('.label-valid');
              label.classList.remove('label-warning');
              label.classList.remove('label-success');
              label.classList.add('label-danger');
              label.querySelector('span').classList.remove('glyphicon-question-sign');
              label.querySelector('span').classList.remove('glyphicon-ok-sign');
              label.querySelector('span').classList.add('glyphicon-remove-sign');
              label.querySelector('.in-label').innerHTML=strings['invalid'];
            }
            $("#saving").hide();
          });
        }
        return false;
    };

  });

  $("form.upload #file").change(function(e){
      $("form.upload #type").val(e.target.files[0].name.match(/\.[a-zA-Z]{3,4}$/)[0].replace(".",""));
  });

  $(".insert").submit(function(){
      return confirm(strings['confirm-insert']);
  });

  $(".delete").click(function(evt){
    if(confirm(strings['confirm-delete'])){
      var id = evt.target.getAttribute('rel');
      $.post(base+'/'+db+'/occurrence/'+id+'/delete',null,function(a,b){
        console.log(a,b);
      });
      document.getElementById('occ-'+id+'-unit').remove();
      updateStats();
    }
    return false;
  });

  function updateStats()  {
    $.getJSON(location.href+'/stats',function(stats){
        for(var k in stats) {
          var el = document.querySelector(".stats-"+k);
          if(el != null) el.innerHTML=stats[k];
        }
    });
  };

  $('.glyphicon-globe.done').each(function(i,e){
    $(e).attr('title','SIG DONE').tooltip();
  });
  $('.glyphicon-globe.notdone').each(function(i,e){
    $(e).attr('title','SIG NOT DONE').tooltip();
  });
  $('.glyphicon-check.done').each(function(i,e){
    $(e).attr('title','Validtion DONE').tooltip();
  });
  $('.glyphicon-check.notdone').each(function(i,e){
    $(e).attr('title','Validation NOT DONE').tooltip();
  });

});

