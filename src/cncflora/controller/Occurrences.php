<?php

namespace cncflora\controller;

use \cncflora\View;

class Occurrences {

  public function specie_t($req,$res,$args) {
    $taxonomia_diferente = urldecode($args['taxonomia_diferente']);
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

    $nomes = explode(";", $taxonomia_diferente);

    $data =[
      'db'=>$db,
      'sig'=>$sig,
      'analysis'=>$analysis,
      'validate'=>$validate,
      'stats'=>$stats,
      'specie'=>$specie,
      'occurrences'=>$occurrences,
      'occurrences_json'=>json_encode($occurrences),
      'taxonomia_diferente'=>true,
      'taxonomia_diferente_scientificNameWithoutAuthorship'=>$nomes[0],
      'taxonomia_diferente_scientificNameAuthorship'=>$nomes[1],
      'eoo_geo_json'=>json_encode($stats['eoo_geo'])
    ];

    $view = new View('occurrences',$data);
    $res->setContent($view);
    return $res;
  }

  public function specie($req,$res,$args) {
    $db = $args['db'];
    $name = urldecode($args['name']);

    $specie =  (new \cncflora\repository\Taxon($db))->getSpecie($name);
    $repo = new \cncflora\repository\Occurrences($db);
    $occurrences = $repo->listOccurrences($name);
    $this->sort_by_field($occurrences, 'stateProvince');

    $stats = $repo->getStats($occurrences);
    $stats['aoo']=number_format($stats['aoo'],2)."km²";

    //Se EOO < AOO ou type=taxon and metadata.eoo == true
    //**eoo = aoo
    if(isset($specie['metadata']['eoo']) && $specie['metadata']['eoo'])
      $stats['eoo']=$stats['aoo'];
    else
      $stats['eoo']=number_format($stats['eoo'],2)."km²";

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
      'occurrences_json'=>json_encode($occurrences),
      'eoo_geo_json'=>json_encode($stats['eoo_geo'])
    ];

    $view = new View('occurrences',$data);
    $res->setContent($view);
    return $res;
  }

  public function downloadFamily($req,$res,$args) {
    $db = $args['db'];
    $family = urldecode($args['family']);
    $to = $args['format'];

    $repo = new \cncflora\repository\Occurrences($db);
    $repoTaxon = new \cncflora\repository\Taxon($db);

    $spps = $repoTaxon->listFamily($family);
    $names = [];
    foreach($spps as $spp) {
      $names = array_merge($names,$repoTaxon->listNames($spp['scientificNameWithoutAuthorship']));
    }

    $occurrences = $repo->flatten($repo->listOccurrences($names,false));

    foreach($occurrences as $i=>$occ) {
      unset($occ['_id']);
      unset($occ['id']);
      foreach($occ as $k=>$v) {
        $occ[$k] = utf8_encode($v);
        if(strpos($v, "Ã") !== false)
          $occ[$k] = utf8_decode($occ[$k]);
      }
      $occurrences[$i] = $occ;
    }

    $client = new \GuzzleHttp\Client();
    $dwc_res = $client->request('POST',DWC_SERVICES.'/api/v1/convert?from=json&to='.$to,['json'=>$occurrences]);

    header('Content-Type: application/octet-stream');
    header("Content-Transfer-Encoding: Binary");
    header("Content-disposition: attachment; filename=\"" .str_replace(" ","_",$family ).".".$to . "\"");
    $res->setContent($dwc_res->getBody());
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
        if(strpos($v, "Ã") !== false)
          $occ[$k] = utf8_decode($occ[$k]);
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
    $this->sort_by_field($occurrences, 'stateProvince');

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
    $flag_occurrence_id = false;
    
    if( !(strpos($id, 'çÇpOp0') === false))
        $id = str_replace('çÇpOp0', '/', $id);

    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);
    if(isset($occ['error']) && $occ['error'] == "not_found"){
      $occ_t = $repo->getOccurrence("occurrence:".$id);
      if(!isset($occ_t['error'])){
          $occ = $occ_t;
          $flag_occurrence_id = true;
      }
    }

    foreach($_POST as $k=>$v) {
      $occ[$k]=$v;
    }

    if($flag_occurrence_id)
      $occ['_id'] = "occurrence:".$occ['_id'];

    //ocorrências com comentários remarks e occurrenceRemarks
    if(isset($occ['remarks']) && ($occ['remarks'] != "")){
      $occ['occurrenceRemarks'] = "";
    }else if(isset($occ['occurrenceRemarks']) && ($occ['occurrenceRemarks'] != "")
      && ((isset($occ['remarks']) && ($occ['remarks'] == "")) || (!isset($occ['remarks'])))){
      $occ['remarks'] = $occ['occurrenceRemarks'];
      $occ['occurrenceRemarks'] = "";
    }

    $repo->updateOccurrence($occ, $flag_occurrence_id);

    header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
    die();
    return $res;
  }

  public function sig($req,$res,$args) {
    $db = $args['db'];
    $id = urldecode($args['id']);
    $flag_occurrence_id = false;

    if( !(strpos($id, 'çÇpOp0') === false))
      $id = str_replace('çÇpOp0', '/', $id);

    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);
    if(isset($occ['error']) && $occ['error'] == "not_found"){
      $occ_t = $repo->getOccurrence("occurrence:".$id);
      if(!isset($occ_t['error'])){
          $occ = $occ_t;
          $flag_occurrence_id = true;
      }
    }

    if(isset($_POST['status']))
      $occ['georeferenceVerificationStatus'] = $_POST['status'];
    $occ['decimalLatitude']= str_replace(",",".",$_POST['decimalLatitude']);
    $occ['decimalLongitude']= str_replace(",",".",$_POST['decimalLongitude']);
    $occ['georeferenceProtocol'] =$_POST['georeferenceProtocol'];
    $occ['georeferenceRemarks'] =$_POST['georeferenceRemarks'];
    $occ['georeferencePrecision'] =$_POST['georeferencePrecision'];
    if(isset($_POST['coordinateUncertaintyInMeters']))
      $occ['coordinateUncertaintyInMeters'] =$_POST['coordinateUncertaintyInMeters'];
    $occ['georeferencedBy'] = $user->name;

    $back=$repo->updateOccurrence($occ, $flag_occurrence_id);
    if( !(strpos($back['occurrenceID'], '/') === false))
      $back['occurrenceID'] = str_replace('/', 'çÇpOp0', $back['occurrenceID']);

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
    $flag_occurrence_id = false;
    
    if( !(strpos($id, 'çÇpOp0') === false))
        $id = str_replace('çÇpOp0', '/', $id);
    
    $user = $_SESSION['user'];
    $repo = new \cncflora\repository\Occurrences($db,$_SESSION['user']);
    $occ = $repo->getOccurrence($id);
    if(isset($occ['error']) && $occ['error'] == "not_found"){
      $occ_t = $repo->getOccurrence("occurrence:".$id);
      if(!isset($occ_t['error'])){
          $occ = $occ_t;
          $flag_occurrence_id = true;
      }
    }

    $occ['validation']['by'] = $user->name;
    foreach($_POST as $k=>$v) {
      $occ['validation'][$k]=$v;
    }

    $back=$repo->updateOccurrence($occ, $flag_occurrence_id);

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

  private function sort_by_field(&$array, $field) {
    usort($array, function ($a, $b) use($field) {
      if(!isset($a[$field])){
        $a[$field] = "";
      }
      if(!isset($b[$field])){
        $b[$field] = "";
      }
      return strnatcmp($a[$field], $b[$field]);
    });
  }

}
