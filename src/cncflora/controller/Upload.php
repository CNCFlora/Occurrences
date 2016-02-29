<?php

namespace cncflora\controller;

use \cncflora\View;

class Upload {

  public function index($req,$res,$args) {
    $data = [
      'db'=>$args['db'],
      'scientificName'=>isset($_GET['scientificName'])?$_GET['scientificName']:"",
      'family'=>isset($_GET['family'])?$_GET['family']:""
    ];
    $res->setContent(new View('upload',$data));
    return $res;
  }

  public function process($req,$res,$args) {
    $types = [
      'xlsx'=> 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'csv'=> 'text/csv'
    ];
    $file = fopen($_FILES['file']['tmp_name'],'rb');
    $client = new \GuzzleHttp\Client();

    $occs=[];
    $ok=false;
    try {
      $type = $_POST['type'];
      $url = DWC_SERVICES.'/api/v1/convert?from='.$type.'&to=json&fixes=true';
      $opts = ['body'=>$file,'headers'=>['Content-Type'=>$types[$type]]];
      $dwc_res = $client->request('POST',$url,$opts);
      $occs = json_decode($dwc_res->getBody(),true);
      $ok=true;
    } catch (Exception $e) {
      var_dump($e);
      $ok=false;
    }

    if($ok) {
      foreach($occs as $k=>$occ) {
        if(count($occ) == 1) {
          unset($occs[$k]);
        }
      }
      $occs = array_values($occs);

      $occs= (new \cncflora\repository\Occurrences($args['db']))->prepareAll($occs,false,true);

      $data = [
        'db'=>$args['db'],
        'uploaded'=>true,
        'occurrences'=>$occs,
        'occurrences_json'=>json_encode($occs)
      ];
    } else {
      $data=[
        'db'=>$args['db'],
        'uploaded'=>false,
        'error'=>true
      ];
    }

    $res->setContent(new View('upload',$data));
    return $res;
  }

  public function insert($req,$res,$args) {
    $occs = json_decode($_POST['json'],'true');
    $names=[];

    $total=0;
    foreach($occs as $i=>$occ) {
      if(!isset($occ['specie']) || $occ['specie'] == null) {
        unset($occs[$i]);
        continue;
      }

      $name = $occ['specie']['scientificNameWithoutAuthorship'];
      if(!isset($names[$name])) $names[$name]=['name'=>$name,'count'=>0];
      $names[$name]['count']++;
      $total++;
    }
    sort($occs);

    (new \cncflora\repository\Occurrences($args['db'],$_SESSION['user']))->insertOccurrences($occs);

    $data = [
      'db'=>$args['db'],
      'inserted'=>true,
      'total'=>$total,
      'names'=>array_values($names)
    ];
    $res->setContent(new View('upload',$data));
    return $res;
  }


  public function add($req,$res,$args) {
    $occ= $_POST;

    (new \cncflora\repository\Occurrences($args['db'],$_SESSION['user']))->insertOccurrence($occ);

    $data = [
      'db'=>$args['db'],
      'inserted'=>true
    ];
    header('Location: '.$_SERVER['HTTP_REFERER'],true,303);
    die();
    return $res;
  }

}

