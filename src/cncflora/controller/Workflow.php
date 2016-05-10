<?php

namespace cncflora\controller;

use \cncflora\View;

class Workflow {

  public function families($request,$response,$args) {
    $db = $args['db'];
    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);
    $families = $repo->listFamilies();

    $fs=[];
    foreach($families as $i=>$f) {
      $spps = $repo->listFamily($f);
      $names = [];
      $got=false;
      foreach($spps as $spp) {
        list($s,$a,$v) = \cncflora\ACL::listPermissions($user,$db,$spp);
        if($s || $a || $v) {
          $names = array_merge($names,$repo->listNames($spp['scientificNameWithoutAuthorship']));
          $got=true;
        }
      }
      if(!$got) {
        continue;
      }
      $occs =  $repoOcc->listOccurrences($names,false);

      $stats = $repoOcc->getStats($occs,false);
      $stats['family']=$f;
      $fs[]=$stats;
    }
    $response->setContent(new View('families',['db'=>$db,'families'=>$fs,'w'=>'workflow/']));
    return $response;
  }

  public function family($req,$res,$args){
    $db = $args['db'];
    $user = $_SESSION['user'];
    $family = $args['family'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);

    $spps = $repo->listFamily($family);

    foreach($spps as $i=>$spp) {
       list($s,$a,$v) = \cncflora\ACL::listPermissions($user,$db,$spp);
       if($s || $a || $v) {
         $occs = $repoOcc->listOccurrences($spp['scientificNameWithoutAuthorship'],false);
         $spps[$i] = array_merge($spp,$repoOcc->getStats($occs,false));
       } else {
         unset($spps[$i]);
       }
    }
    sort($spps);

    $res->setContent(new View('family',['db'=>$db,'species'=>$spps,'family'=>$family]));
    return $res;
  }

}


