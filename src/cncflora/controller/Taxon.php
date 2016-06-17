<?php

namespace cncflora\controller;

use \cncflora\View;

class Taxon {

  public function families($request,$response,$args) {
    $db = $args['db'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);
    $families = $repo->listFamilies();

    $fs=[];
    foreach($families as $f) {
      $spps = $repo->listFamily($f);
      $names = [];
      foreach($spps as $spp) {
        $names = array_merge($names,$repo->listNames($spp['scientificNameWithoutAuthorship']));
      }
      $occs =  $repoOcc->listOccurrences($names,false);

      $stats = $repoOcc->getStats($occs,false);
      $stats['family']=$f;
      $fs[]=$stats;
    }
    $response->setContent(new View('families',['db'=>$db,'families'=>$fs]));
    return $response;
  }

  public function family($req,$res,$args){
    $db = $args['db'];
    $family = $args['family'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);

    $spps = $repo->listFamily($family);

    foreach($spps as $i=>$spp) {
       $occs = $repoOcc->listOccurrences($spp['scientificNameWithoutAuthorship'],false);
       $spps[$i] = array_merge($spp,$repoOcc->getStats($occs,false));
    }

    usort($spps,function($s0,$s1){
      return strcmp(trim(strtolower($s0['scientificNameWithoutAuthorship'])),trim(strtolower($s1['scientificNameWithoutAuthorship'])));
    });

    $res->setContent(new View('family',['db'=>$db,'species'=>$spps,'family'=>$family]));
    return $res;
  }

}

