<?php

namespace cncflora\controller;

use \cncflora\View;

class Taxon {

  public function families($request,$response,$args) {
    $db = $args['db'];
    $repo = new \cncflora\repository\Taxon($db);
    $families = $repo->listFamilies();

    $fs=[];
    foreach($families as $f) {
      $fs[]=['family'=>$f];
    }
    $response->setContent(new View('families',['db'=>$db,'families'=>$fs]));
    return $response;
  }

  public function family($req,$res,$args){
    $db = $args['db'];
    $family = $args['family'];
    $repo = new \cncflora\repository\Taxon($db);
    $spps = $repo->listFamily($family);
    $res->setContent(new View('family',['db'=>$db,'species'=>$spps,'family'=>$family]));
    return $res;
  }

}

