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
      $occs[]=$this->fix($hit['_source']);
    }

    return $occs;
  }

  public function getOccurrence($id) {
  }

  public function insertOccurrence($occurrence){
  }

  public function insertOccurrences($occurrences) {
  }

  public function updateOccurrence($occurrence) {
  }

  public function updateOccurrences($occurrences) {
  }

  public function canUse($occ) {
    return $this->isValid($occ) && $this->isSigOk($occ);
  }

  public function isValid($occ) {
    return $occ['status'] === "true";
  }

  public function isSigOk($occ) {
    return isset($doc["georeferenceVerificationStatus"]) && $doc["georeferenceVerificationStatus"] == "ok";
  }

  public function fix($doc) {
    if(isset($doc["georeferenceVerificationStatus"])) {
      if($doc["georeferenceVerificationStatus"] == "1" || $doc["georeferenceVerificationStatus"] == "ok") {
        $doc["georeferenceVerificationStatus"] = "ok";
      }
    }

    if(isset($doc["validation"])) {
      if(is_object($doc["validation"])) {
        foreach($doc["validation"] as $k=>$v) {
          $kk = 'validation_'.$k;
          $doc[$kk]=$v;
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
    return $doc;
  }
}
