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

    $data =[
      'db'=>$db,
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

