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
    $occurrences = $repo->listOccurrences($name);

    foreach($occurrences as $i=>$occ) {
      foreach($occ as $k=>$v) {
        if(strpos($k,'-') >= 1) {
          unset($occurrences[$i][$k]);
        }else if(is_array($v)) {
          foreach($v as $kk=>$vv) {
            if(strpos($kk,'-') >= 1) {
              unset($occurrences[$i][$k][$kk]);
            }else if(is_string($vv) || is_integer($vv) || is_double($vv)) {
              $occurrences[$i][$k."_".$kk]=  $vv;
            } else if(is_bool($vv)) {
              $occurrences[$i][$k."_".$kk]=  $vv?"true":"false";
            }
          }
          unset($occurrences[$i][$k]);
        } else if(is_bool($v)) {
          $occurrences[$i][$k] = $v?"true":"false";
        }
      }
    }

    $client = new \GuzzleHttp\Client();
    $dwc_res = $client->request('POST',DWC_SERVICES.'/api/v1/convert?from=json&to='.$to,['json'=>$occurrences]);

    header('Content-Type: application/octet-stream');
    header("Content-Transfer-Encoding: Binary"); 
    header("Content-disposition: attachment; filename=\"" .str_replace(" ","_",$name ).".".$to . "\"");
    $res->setContent($dwc_res->getBody());
    return $res;
  }

  public function stats($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);
    $stats = $repo->getSats($occurrences);

    $res->setContent(json_encode($stats));
    return $res;
  }

  public function analysis($req,$res,$args) {
    $db = $args['db'];
    $id = $args['id'];

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
    $id = $args['id'];

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

    $repo->updateOccurrence($occ);

    header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
    die();
    return $res;
  }

  public function validate($req,$res,$args){
    $db = $args['db'];
    $id = $args['id'];

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);

    $occ['validation']['by'] = $user->name;
    foreach($_POST as $k=>$v) {
      $occ['validation'][$k]=$v;
    }

    $back=$repo->updateOccurrence($occ);

    header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
    die();
    return $res;
  }
}

