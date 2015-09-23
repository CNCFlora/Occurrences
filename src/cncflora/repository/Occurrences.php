<?php

namespace cncflora\repository;

class Occurrences {

  public $couchdb = null;
  public $db = null;
  public $elasticsearch=null;

  public function __construct($db) {
    $this->db=$db;
    $this->couchdb = \cncflora\Config::couchdb($db);
    $this->elasticsearch = \cncflora\Config::elasticsearch();
  }

  public function listOccurrences($name) {
    $names = (new Taxon($this->db))->listNames($name);

    $occs=[];

    $params=[
      'index'=>$this->db,
      'type'=>'occurrence',
      'body'=>[
        'query'=>[
          'bool'=>[
            'should'=>[
            ]
          ]
        ]
      ]
    ];

    foreach($names as $name) {
      $params['body']['query']['bool']['should'][]
        = ['match'=>['acceptedNameUsage'=>['query'=>$name,'operator'=>'and']]];
      $params['body']['query']['bool']['should'][]
        = ['match'=>['scientificName'=>['query'=>$name,'operator'=>'and']]];
      $params['body']['query']['bool']['should'][]
        = ['match'=>['scientificNameWithoutAuthorship'=>['query'=>$name,'operator'=>'and']]];

      $parts = explode(" ",$name);
      $params['body']['query']['bool']['should'][]
        = ['bool'=>['must'=>[['match'=>['genus'=>$parts[0]]],['match'=>['specificEpithet'=>$parts[1]]]]]];
    }

    $result = $this->elasticsearch->search($params);
    foreach($result['hits']['hits'] as $hit) {
      if(isset($hit['_source']['deleted'])) continue;
      $occs[]=$hit['_source'];
    }
    $occs=$this->fixAll($occs);

    return $occs;
  }

  public function getOccurrence($id) {
    return $this->fix($this->couchdb->findDocument($id)->body);
  }

  public function insertOccurrence($occurrence){
    $occurrence=$this->fix($occurrence);

    $occurrence['metadata']['created']=time();
    $occurrence['metadata']['modified']=time();

    try {
      $r=$this->couchdb->postDocument($occurrence);
      $occurrence['_rev']=$r[1];
      $ri=$this->elasticsearch->index([
        'index'=>$this->db,
        'type'=>'occurrence',
        'id'=>$occurrence['_id'],
        'body'=>$occurrence
      ]);
      sleep(1);
      return $occurrence;
    } catch(Exception $e) {
      return false;
    }
  }

  public function insertOccurrences($occurrences) {
    $occurrences=$this->fixAll($occurrences);

    $occurrence['metadata']['created']=time();
    $occurrence['metadata']['modified']=time();

    $bulk=$this->couchdb->createBulkUpdater();
    $bulk->updateDocuments($occurrences);
    $res=$bulk->execute();
    if(isset($r->body->error)){
      return false;
    }

    foreach($res->body as $i=>$r) {
      $occurrences[$i]['_rev']=$r['rev'];
      $ri=$this->elasticsearch->index([
        'index'=>$this->db,
        'type'=>'occurrence',
        'id'=>$occurrences[$i]['_id'],
        'body'=>$occurrences[$i]
      ]);
    }
    sleep(1);

    return $occurrences;
  }

  public function updateOccurrence($occurrence) {
    $occurrence=$this->fix($occurrence);
    $occurrence['metadata']['modified']=time();
    try {
      $r=$this->couchdb->postDocument($occurrence);
      $occurrence['_rev']=$r[1];
      $ri=$this->elasticsearch->index([
        'index'=>$this->db,
        'type'=>'occurrence',
        'id'=>$occurrence['_id'],
        'body'=>$occurrence
      ]);
      sleep(1);
      return $occurrence;
    } catch(Exception $e) {
      return false;
    }
  }

  public function updateOccurrences($occurrences) {
    $occurrences=$this->fixAll($occurrences);

    foreach($occurrences as $i=>$occ) {
      $occurrences[$i]['metadata']['modified']=time();
    }

    $bulk=$this->couchdb->createBulkUpdater();
    $bulk->updateDocuments($occurrences);
    $res=$bulk->execute();
    if(isset($r->body->error)){
      return false;
    }

    foreach($res->body as $i=>$r) {
      $occurrences[$i]['_rev']=$r['rev'];
      $ri=$this->elasticsearch->index([
        'index'=>$this->db,
        'type'=>'occurrence',
        'id'=>$occurrences[$i]['_id'],
        'body'=>$occurrences[$i]
      ]);
    }
    sleep(1);

    return $occurrences;
  }

  public function deleteOccurrence($occurrence){
    $occurrence['deleted']=true;
    $this->updateOccurrence($occurrence);
  }

  public function canUse($occ) {
    return $this->isValid($occ) && $this->isSigOk($occ);
  }

  public function isValid($occ) {
    return $occ['valid'] === "true";
  }

  public function isSigOk($occ) {
    return isset($doc["georeferenceVerificationStatus"]) && $doc["georeferenceVerificationStatus"] == "ok";
  }

  public function fixAll($docs) {
    $client = new \GuzzleHttp\Client();
    $res = $client->request('POST',DWC_SERVICES.'/api/v1/fix',['json'=>$docs]);
    $redocs = json_decode($res->getBody(),true);

    foreach($redocs as $i=>$redoc){
      foreach($redoc as $k=>$v) {
        $docs[$i][$k] = $v;
      }
    }

    foreach($docs as $i=>$doc) {
      $docs[$i] = $this->fix($doc,false);
    }

    return $docs;
  }

  public function fix($doc,$dwc=true) {
    if($dwc) {
      $client = new \GuzzleHttp\Client();
      $res = $client->request('POST',DWC_SERVICES.'/api/v1/fix',[
        'json'=>[$doc]]);
      $redoc = json_decode($res->getBody(),true);
      foreach($redoc[0] as $k=>$v) {
        $doc[$k] = $v;
      }
    }

    if(isset($doc["occurrenceID"])) {
      $doc["_id"] = $doc["occurrenceID"];
    }else{
      $doc['_id'] = 'occurrence:'.uniqid(true);
    }

    if(!isset($doc['metadata'])) {
      $doc['metadata']=[];
    }

    $doc['metadata']['type']='occurrence';

    $doc['metadata']['modified_date'] = date('Y-m-d',$doc['metadata']['modified']);
    $doc['metadata']['created_date'] = date('Y-m-d',$doc['metadata']['created']);

    if(isset($doc["georeferenceVerificationStatus"])) {
      if($doc["georeferenceVerificationStatus"] == "1" || $doc["georeferenceVerificationStatus"] == "ok") {
        $doc["georeferenceVerificationStatus"] = "ok";
      }
    }

    if(isset($doc["validation"])) {
      if(is_array($doc["validation"])) {
        foreach($doc["validation"] as $k=>$v) {
          $kk = $k."-".$v;
          $doc['validation'][$kk]=$v;
        }

        if(isset($doc["validation"]["status"])) {
          if($doc["validation"]["status"] == "valid") {
            $doc["valid"]="true";
          } else if($doc["validation"]["status"] == "invalid") {
            $doc["valid"]="false";
          } else {
            $doc["valid"]="";
          }
        } else {
          if(
            (
                 !isset($doc["validation"]["taxonomy"])
              || $doc["validation"]["taxonomy"] == null
              || $doc["validation"]["taxonomy"] == 'valid'
            )
            &&
            (
                 !isset($doc["validation"]["georeference"])
              || $doc["validation"]["georeference"] == null
              || $doc["validation"]["georeference"] == 'valid'
            )
            && 
            (
                 !isset($doc["validation"]["native"])
              || $doc["validation"]["native"] == null
              || $doc["validation"]["native"] != 'non-native'
            )
            && 
            (
                 !isset($doc["validation"]["presence"])
              || $doc["validation"]["presence"] == null
              || $doc["validation"]["presence"] != 'absent'
            )
            && 
            (
                 !isset($doc["validation"]["cultivated"])
              || $doc["validation"]["cultivated"] == null
              || $doc["validation"]["cultivated"] != 'yes'
            )
            && 
            (
                 !isset($doc["validation"]["duplicated"])
              || $doc["validation"]["duplicated"] == null
              || $doc["validation"]["duplicated"] != 'yes'
            )
          ) {
            $doc["valid"]="true";
          } else {
            $doc["valid"]="false";
          }
        }
      } else {
        $doc["valid"] = "";
      }
    } else {
      $doc["valid"] = "";
    }

    $doc['metadata']['status'] = $this->canUse($doc)?"valid":"invalid";

    return $doc;
  }
}
