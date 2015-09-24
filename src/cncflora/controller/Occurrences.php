<?php

namespace cncflora\controller;

use \cncflora\View;

class Occurrences {

  public function specie($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $specie =  (new \cncflora\repository\Taxon($db))->getSpecie($name);
    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);

    $user = $_SESSION['user'];

    $sig=false;
    $analysis=false;
    $validate=true;
    foreach($user->roles as $role) {
      if($role->context == $db) {
        foreach($role->roles as $sub_role) {
          if(strtolower($sub_role->role) == 'sig') {
            $sig=true;
          } else if(strtolower($sub_role->role) == 'analyst') {
            foreach($sub_role->entities as $ent) {
              $ent = strtolower($ent);
              if($ent == 'all' 
                || $ent == strtolower($specie->family) 
                || $ent == strtolower($specie->scientificNameWithoutAuthorship)) {
                $analysis=true;
              }
            }
          } else if(strtolower($sub_role->role) == 'validator') {
            foreach($sub_role->entities as $ent) {
              $ent = strtolower($ent);
              if($ent == 'all' 
                || $ent == strtolower($specie->family) 
                || $ent == strtolower($specie->scientificNameWithoutAuthorship)) {
                $validate=true;
              }
            }
          }
        }
      }
    }

    $data =[
      'db'=>$db,
      'sig'=>$sig,
      'analysis'=>$analysis,
      'validate'=>$validate,
      'specie'=>$specie,
      'occurrences'=>$occurrences,
      'occurrences_json'=>json_encode($occurrences)
    ];

    $view = new View('occurrences',$data);
    $res->setContent($view);
    return $res;
  }

  public function occurrences($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);

    $res->setContent(json_encode($occurrences));
    return $res;
  }
}

