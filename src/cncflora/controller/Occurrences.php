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
    $stats = $repo->getStats($occurrences);
    $stats['eoo']=number_format($stats['eoo'],2)."km²";
    $stats['aoo']=number_format($stats['aoo'],2)."km²";

    $user = $_SESSION['user'];

    list($sig,$analysis,$validate) = \cncflora\ACL::listPermissions($user,$db,$specie);

    $data =[
      'db'=>$db,
      'sig'=>$sig,
      'analysis'=>$analysis,
      'validate'=>$validate,
      'stats'=>$stats,
      'specie'=>$specie,
      'occurrences'=>$occurrences,
      'occurrences_json'=>json_encode($occurrences)
    ];

    $view = new View('occurrences',$data);
    $res->setContent($view);
    return $res;
  }

  public function download($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);
    $to = $args['format'];

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->flatten($repo->listOccurrences($name));

    foreach($occurrences as $i=>$occ) {
      unset($occ['_id']);
      unset($occ['id']);
      foreach($occ as $k=>$v) {
        $occ[$k] = utf8_encode($v);
      }
      $occurrences[$i] = $occ;
    }

    $client = new \GuzzleHttp\Client();
    $dwc_res = $client->request('POST',DWC_SERVICES.'/api/v1/convert?from=json&to='.$to,['json'=>$occurrences]);

    header('Content-Type: application/octet-stream');
    header("Content-Transfer-Encoding: Binary"); 
    header("Content-disposition: attachment; filename=\"" .str_replace(" ","_",$name ).".".$to . "\"");
    $res->setContent($dwc_res->getBody());
    return $res;
  }

  public function table($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $specie =  (new \cncflora\repository\Taxon($db))->getSpecie($name);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);

    $data =[
      'db'=>$db,
      'occurrences'=>$occurrences,
      'occurrences_json'=>json_encode($occurrences),
      'specie'=>$specie
    ];
    $view = new View('table',$data);
    $res->setContent($view);
    return $res;
  }

  public function occurrences($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->flatten($repo->listOccurrences($name));

    $res->setContent(json_encode($occurrences));
    return $res;
  }

  public function stats($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);
    $stats = $repo->getStats($occurrences);

    $stats['eoo']=number_format($stats['eoo'],2)."km²";
    $stats['aoo']=number_format($stats['aoo'],2)."km²";

    header('Content-Type: application/json');
    $res->setContent(json_encode($stats));
    return $res;
  }

  public function analysis($req,$res,$args) {
    $db = $args['db'];
    $id = urldecode($args['id']);

    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    foreach($_POST as $k=>$v) {
      $occ[$k]=$v;
    }

    $repo->updateOccurrence($occ);

    header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
    die();
    return $res;
  }

  public function sig($req,$res,$args) {
    $db = $args['db'];
    $id = urldecode($args['id']);

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    $occ['georeferenceVerificationStatus'] = $_POST['status'];
    $occ['decimalLatitude']= str_replace(",",".",$_POST['decimalLatitude']);
    $occ['decimalLongitude']= str_replace(",",".",$_POST['decimalLongitude']);
    $occ['georeferenceProtocol'] =$_POST['georeferenceProtocol'];
    $occ['georeferenceRemarks'] =$_POST['georeferenceRemarks'];
    $occ['coordinateUncertaintyInMeters'] =$_POST['coordinateUncertaintyInMeters'];
    $occ['georeferencedBy'] = $user->name;

    $back=$repo->updateOccurrence($occ);

    if($_GET['raw']) {
      header('Content-Type: application/json');
      $res->setContent(json_encode($back));
      return $res;
    } else {
      header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
      die();
    }
  }

  public function validate($req,$res,$args){
    $db = $args['db'];
    $id = urldecode($args['id']);

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    $occ['validation']['by'] = $user->name;
    foreach($_POST as $k=>$v) {
      $occ['validation'][$k]=$v;
    }

    $back=$repo->updateOccurrence($occ);

    if($_GET['raw']) {
      header('Content-Type: application/json');
      $res->setContent(json_encode($back));
      return $res;
    } else {
      header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
      die();
    }
  }
  public function data($req,$res,$args){
    $db = $args['db'];
    $id = urldecode($args['id']);
    $field = $args['field'];
    $value = $_POST['value'];

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    $occ[$field] = $value;

    $back=$repo->updateOccurrence($occ);

    $res->setContent(json_encode($back));
    return $res;
  }
  public function delete($req,$res,$args){
    $db = $args['db'];
    $id = urldecode($args['id']);

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    $occ['deleted']=true;

    $back=$repo->updateOccurrence($occ);

    $res->setContent(json_encode($back));
    return $res;
  }
  public function occurrence($req,$res,$args) {
    $db = $args['db'];
    $id = urldecode($args['id']);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrence = $repo->flatten($repo->getOccurrence($id));

    $res->setContent(json_encode($occurrence));
    return $res;
  }


}

