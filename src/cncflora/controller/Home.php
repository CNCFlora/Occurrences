<?php

namespace cncflora\controller;

use \cncflora\View;

class Home {

  public function index($request,$response,$args) {
    $repo = new \cncflora\repository\Checklist;
    $dbs=[];
    $list=$repo->getChecklists();
    foreach($list as $db) {
      $dbs[]=['db'=>$db,'name'=>strtoupper(str_replace("_"," ",$db))];
    }
    $response->setContent(new View('index',['dbs'=>$dbs]));
    return $response;
  }

  public function login($req,$res,$args) {
    $preuser = json_decode($_POST['user']);
    if(ENV=='test') {
      $_SESSION['user']=$preuser;
      $_SESSION['logged']=true;
      $res->setContent(json_encode($preuser));
    } else {
      $client = new \GuzzleHttp\Client();
      $res = $client->request('GET', CONNECT.'/api/token?token='.$preuser->token);
      $user = json_decode($res->getBody());
      $_SESSION['user']=$user;
      $_SESSION['logged']=true;
      $res->setContent(json_encode($user));
    }
    return $res;
  }

  public function logout($req,$res,$args){
    $_SESSION['user']=null;
    $_SESSION['logged']=false;
    return $res;
  }

}
