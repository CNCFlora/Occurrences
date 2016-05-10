<?php

namespace cncflora\repository;

class Occurrences {

  public $couchdb = null;
  public $db = null;
  public $elasticsearch=null;
  public $user = null;

  public function __construct($db,$user=null) {
    $this->db=$db;
    $this->couchdb = \cncflora\Config::couchdb($db);
    $this->elasticsearch = \cncflora\Config::elasticsearch();
    $this->user = $user;
  }

  public function listOccurrences($name,$fix=true) {
    if(is_array($name)) {
      $names=$name;
    } else {
      $names = (new Taxon($this->db))->listNames($name);
    }

    $occs=[];

    $params=[
      'index'=>$this->db,
      'type'=>'occurrence',
      'body'=>[
        'size'=> 9999,
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
      $params['body']['query']['bool']['should'][]
        = ['match'=>['specificEpithet'=>['query'=>$name,'operator'=>'and']]];

      $parts = explode(" ",$name);
      $params['body']['query']['bool']['should'][]
        = ['bool'=>['must'=>[['match'=>['genus'=>$parts[0]]],['match'=>['specificEpithet'=>$parts[1]]]]]];
    }

    $result = $this->elasticsearch->search($params);
    foreach($result['hits']['hits'] as $hit) {
      if(isset($hit['_source']['deleted'])) continue;
      $occs[]=$hit['_source'];
    }
    $occs=$this->prepareAll($occs,$fix);

    usort($occs,function($a,$b) { return strcmp($a['occurrenceID'],$b['occurrenceID']);});

    return $occs;
  }

  public function getOccurrence($id) {
    $doc=$this->prepare($this->couchdb->findDocument($id)->body);
    return $doc;
  }

  public function insertOccurrence($occurrence){
    $occurrence=$this->fix($occurrence);

    $occurrence['metadata']['created']=time();
    $occurrence['metadata']['modified']=time();

    if($this->user != null) {
      $occurrence['metadata']['contributor'] = $this->user->name;
      $occurrence['metadata']['contact'] = $this->user->email;
      $occurrence['metadata']['creator'] = $this->user->name;
    }

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

    foreach($occurrences as $i=>$occurrence) {
      $occurrence['metadata']['created']=time();
      $occurrence['metadata']['modified']=time();

      if($this->user != null) {
        $occurrence['metadata']['contributor'] = $this->user->name;
        $occurrence['metadata']['contact'] = $this->user->email;
        $occurrence['metadata']['creator'] = $this->user->name;
      }

      $occurrences[$i] = $occurrence;
    }

    $bulk=$this->couchdb->createBulkUpdater();
    $bulk->updateDocuments($occurrences);
    $res=$bulk->execute();
    if(isset($r->body->error)){
      return false;
    }

    foreach($res->body as $i=>$r) {
      if(isset($r['error'])) {
        unset($occurrences[$i]);
      } else {
        $occurrences[$i]['_rev']=$r['rev'];
        $ri=$this->elasticsearch->index([
          'index'=>$this->db,
          'type'=>'occurrence',
          'id'=>$occurrences[$i]['_id'],
          'body'=>$occurrences[$i]
        ]);
      }
    }
    sleep(1);

    return array_values($occurrences);
  }

  public function updateOccurrence($occurrence) {
    if($occurrence == null || isset($occurrence['error'])) return false;
    $occurrence=$this->metalog($this->fix($occurrence));
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
      return $this->prepare($occurrence,false);
    } catch(Exception $e) {
      return false;
    }
  }

  public function updateOccurrences($occurrences) {
    $occurrences=$this->fixAll($occurrences);

    foreach($occurrences as $i=>$occ) {
      $occurrences[$i] = $this->metalog($occ);
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

    return $this->prepareAll($occurrences,false);
  }

  public function deleteOccurrence($occurrence){
    $occurrence['deleted']=true;
    $this->updateOccurrence($occurrence);
  }


  public function getStats($occurrences,$calc=true){
    $stats = [
      'total'=>0,
      'eoo'=>'n/a',
      'aoo'=>'n/a',
      'validated'=>0,
      'not_validated'=>0,
      'valid'=>0,
      'invalid'=>0,
      'sig_reviewed'=>0,
      'not_sig_reviewed'=>0,
      'sig_ok'=>0,
      'sig_nok'=>0,
      'can_use'=>0,
      'can_not_use'=>0,
      'validation_done'=>false,
      'sig_done'=>false,
      'done'=>false
    ];

    $stats['total']=count($occurrences);
    $to_calc=[];
    foreach($occurrences as $occ){
      if($this->canUse($occ)) {
        $stats['can_use']++;
        $to_calc[]=['decimalLatitude'=>$occ['decimalLatitude'],'decimalLongitude'=>$occ['decimalLongitude']];
      } else {
        $stats['can_not_use']++;
      }
      if($this->isValidated($occ)) {
        $stats['validated']++;
        if($this->isValid($occ)) {
          $stats['valid']++;
        } else {
          $stats['invalid']++;
        }
      } else {
        $stats['not_validated']++;
      }
      if($this->hasSig($occ)) {
        $stats['sig_reviewed']++;
        if($this->isSigOK($occ)) {
          $stats['sig_ok']++;
        } else {
          $stats['sig_nok']++;
        }
      } else {
        $stats['not_sig_reviewed']++;
      }
    }

    if($calc) {
      $client = new \GuzzleHttp\Client();
      $res = $client->request('POST',DWC_SERVICES.'/api/v1/analysis/all',['json'=>$to_calc]);
      $calc = json_decode($res->getBody(),true);

      $stats['eoo']=$calc['eoo']['all']['area'];
      $stats['aoo']=$calc['aoo']['all']['area'];
    }

    $stats['validation_done']=$stats['validated']==$stats['total'];
    $stats['sig_done']=$stats['sig_reviewed']==$stats['total'];
    $stats['done']=$stats['sig_done']&&$stats['validation_done'];

    return $stats;
  }

  public function canUse($occ) {
    return (!$this->isValidated($occ) || $this->isValid($occ)) && $this->isSigOk($occ);
  }

  public function isValid($occ) {
    return $occ['valid'] === true;
  }

  public function isValidated($occ) {
    return isseT($occ['validation']) && isset($occ['validation']['done']) && $occ['validation']['done']===true;
  }

  public function hasSig($occ) {
    return (isset($occ['georeferenceVerificationStatus']) && strlen($occ['georeferenceVerificationStatus']) >= 2);
  }
  public function isSigOk($occ) {
    return isset($occ["georeferenceVerificationStatus"]) && $occ["georeferenceVerificationStatus"] == "ok";
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
    return $docs;
  }

  public function prepareAll($docs,$fix=true,$taxon=false) {
    if($fix) $docs=$this->fixAll($docs);

    foreach($docs as $i=>$doc) {
      $docs[$i] = $this->prepare($doc,false,$taxon);
    }

    return $docs;
  }

  public function fix($doc) {
    $doc=$this->fixId($doc);

    $client = new \GuzzleHttp\Client();
    $res = $client->request('POST',DWC_SERVICES.'/api/v1/fix',[
      'json'=>[$doc]]);
    $redoc = json_decode($res->getBody(),true);
    foreach($redoc[0] as $k=>$v) {
      $doc[$k] = $v;
    }

    if(isset($doc['validation'])) {
      foreach($doc['validation'] as $k=>$v) {
        if(strpos($k,'-') >0) {
          unset($doc['validation'][$k]);
        }
      }
    }

    $doc=$this->fixId($doc);

    return $doc;
  }

  public function fixId($doc) {
    if(!isset($doc['_id']) && isset($doc['occurrenceID'])) {
      $doc['_id'] = $doc['occurrenceID'];
    } else if(!isset($doc['_id']) && !isset($doc['occurrenceID'])) {
      $doc['_id'] = 'occurrence:'.uniqid(true);
      $doc['occurrenceID'] = $doc['_id'];
    }

    if(!isset($doc['_id'])) {
      $doc['_id'] = 'occurrence:'.uniqid(true);
    }

    if(!isset($doc["occurrenceID"])) {
      $doc['occurrenceID'] = $doc['_id'];
    }

    $doc['_id'] = $doc['occurrenceID'];
    return $doc;
  }

  public function prepare($doc,$dwc=true,$taxon=false) {
    $doc = $this->fixId($doc);

    if($dwc) {
      $doc=$this->fix($doc);
    }

    if($taxon) {
      $doc=$this->fixSpecie($doc);
    }

    $doc = $this->fixId($doc);

    if(!isset($doc['metadata'])) {
      $doc['metadata']=[];
    }

    $doc['metadata']['type']='occurrence';

    if(isset($doc['metadata']['modified'])) {
      $doc['metadata']['modified_date'] = date('Y-m-d',(int)$doc['metadata']['modified']);
    }
    if(isset($doc['metadata']['created'])) {
      $doc['metadata']['created_date'] = date('Y-m-d',(int)$doc['metadata']['created']);
    }

    if(isset($doc["georeferenceVerificationStatus"])) {
      if($doc["georeferenceVerificationStatus"] == "1" || $doc["georeferenceVerificationStatus"] == "ok") {
        $doc["georeferenceVerificationStatus"] = "ok";
        $doc['sig-ok']=true;
      } else {
        $doc['sig-ok']=false;
      }

      $geos=$doc['georeferenceVerificationStatus'];
      if($geos=='ok') {
        $doc['sig-status-ok']=true;
        $doc['sig-status-nok']=false;
        $doc['sig-status-uncertain-locality']=false;
      }else if($geos=='nok') {
        $doc['sig-status-ok']=false;
        $doc['sig-status-nok']=true;
        $doc['sig-status-uncertain-locality']=false;
      }else if($geos=='uncertain-locality') {
        $doc['sig-status-ok']=false;
        $doc['sig-status-nok']=false;
        $doc['sig-status-uncertain-locality']=true;
      }
    } else {
      $doc['sig-ok']=null;
    }

    $verbatim = null;
    if(isset($doc["verbatimValidation"])) {
      $vvv = $doc["verbatimValidation"];
      if($vvv != null && is_array($vvv) && isset($vvv["status"]) && $vvv["status"] != null) {
        $status = $vvv["status"];
        if($status == "valid" || $status == '1' || $status == 1 || $status == true) {
          $verbatim=true;
        } else {
          $verbatim=false;
        }
      }
    }

    if(isset($doc["validation"])) {
      if(is_array($doc["validation"])) {
        if(isset($doc["validation"]["status"])) {
          if($doc["validation"]["status"] == "" || $doc["validation"]["status"] == null) {
            unset($doc['validation']['status']);
          }
        }
        if(isset($doc["validation"]["remarks"])) {
          if($doc["validation"]["remarks"] == "" || $doc["validation"]["remarks"] == null) {
            unset($doc['validation']['remarks']);
          }
        }
        if(isset($doc["validation"]["by"])) {
          if($doc["validation"]["by"] == "" || $doc["validation"]["by"] == null) {
            unset($doc['validation']['by']);
          }
        }
      }
      if($doc["validation"]==[]) {
        unset($doc["validation"]);
      }
    }

    if(!isset($doc['validation']) && $verbatim != null){
      $doc['validation']=['done'=>true,'valid'=>$verbatim,'status'=>($verbatim?'valid':'invalid')];
      $doc['valid']=$verbatim;
    } else if(!isset($doc['validation'])){
      $doc['validation']=['done'=>false,'valid'=>null,'status'=>''];
      $doc["valid"]=null;
    } else if(isset($doc["validation"])) {
      if(!is_array($doc['validation'])) {
        $doc['validation']=['done'=>false,'valid'=>null,'status'=>''];
        $doc["valid"]=null;
      } else if(is_array($doc["validation"])) {
        foreach($doc["validation"] as $k=>$v) {
          if(is_string($v)) {
            $kk = $k."-".$v;
            $doc['validation'][$kk]=$v;
          }
        }

        if(isset($doc["validation"]["status"])
          && $doc["validation"]["status"] != ""
          && $doc["validation"]["status"] != null) {
          if($doc["validation"]["status"] == "valid") {
            $doc["valid"]=true;
            $doc['validation']['done']=true;
          } else if($doc["validation"]["status"] == "invalid") {
            $doc["valid"]=false;
            $doc['validation']['done']=true;
          } else {
            $doc["valid"]=null;
            $doc['validation']['done']=false;
          }
        } else {
          if(
            !isset($doc["validation"]["taxonomy"])
           && !isset($doc["validation"]["georeference"])
           && !isset($doc["validation"]["native"])
           && !isset($doc["validation"]["presence"])
           && !isset($doc["validation"]["cultivated"])
           && !isset($doc["validation"]["duplicated"])
          ) {
            $doc["valid"]=null;
            $doc['validation']['done']=false;
          } else if(
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
            $doc["valid"]=true;
            $doc['validation']['done']=true;
          } else {
            $doc["valid"]=false;
            $doc['validation']['done']=true;
          }
        }
      } else {
        $doc["valid"] = null;
        $doc['validation']['done']=false;
      }
    } else {
      $doc["valid"] = null;
      $doc['validation']['done']=false;
    }

    $doc['metadata']['status'] = $this->canUse($doc)?"valid":"invalid";

    return $doc;
  }

  public function metalog($occurrence) {
    $metadata = $occurrence['metadata'];

    if(!isset($metadata['concat'])) {
      $metadata['contact']='';
    }
    if(!isset($metadata['concat'])) {
      $metadata['contributor']='';
    }

    if($this->user != null) {
      if(strpos($metadata['contact'],$this->user->email) === false) {
        $metadata['contributor'] = $this->user->name ." ; ".$metadata['contributor'];
        $metadata['contact'] = $this->user->email ." ; ".$metadata['contact'];
      }
    }

    $contributors = explode(" ; ",$metadata['contributor']);
    $contributorsFinal = array();
    foreach($contributors as $contributor) {
      if($contributor != null && strlen($contributor) >= 3) {
        $contributorsFinal[] = $contributor;
      }
    }
    $metadata['contributor'] = implode(" ; ",$contributorsFinal);

    $contacts = explode(" ; ",$metadata['contact']);
    $contactsFinal = array();
    foreach($contacts as $contact) {
      if($contact != null && strlen($contact) >= 3) {
        $contactsFinal[] = $contact;
      }
    }
    $metadata['contact'] = implode(" ; ",$contactsFinal);

    $metadata['modified'] = time();
    $occurrence[ 'metadata' ] = $metadata;
    return $occurrence;
  }


  public function fixSpecie($occ) {

    $name = null; 
    if(isset( $occ["acceptedNameUsage"] ) && strlen(trim( $occ["acceptedNameUsage"]) ) >= 5){
      $name=trim($occ["acceptedNameUsage"]);
    } else if(isset( $occ["scientificNameWithoutAuthorship"] ) && strlen(trim( $occ["scientificNameWithoutAuthorship"] )) >= 3) {
      $name=trim($occ["scientificNameWithoutAuthorship"]);
    } else if(isset($occ["scientificName"]) && strlen(trim( $occ["scientificName"] )) >=5) {
      $name=trim($occ["scientificName"]);
    } else if(
          isset( $occ["genus"] ) && strlen(trim( $occ["genus"] )) >=5
       && isset( $occ["specificEpithet"] ) && strlen(trim( $occ["specificEpithet"] )) >=5
    ) {
      $name=trim($occ["genus"])." ".trim($occ["specificEpithet"]);
    }

      $params['body']['query']['bool']['should'][]
        = ['match'=>['scientificName'=>['query'=>$name,'operator'=>'and']]];
      $params['body']['query']['bool']['should'][]
        = ['match'=>['scientificNameWithoutAuthorship'=>['query'=>$name,'operator'=>'and']]];

    $occ['specie']=null;

    if($name != null) {
      $params=[
        'index'=>$this->db,
        'type'=>'taxon',
        'body'=>[
          'size'=> 9999,
          'query'=>[
            'multi_match'=>[
            'query'=>$name,
            'operator'=>'and',
            'fields'=>['scientificName','scientificNameWithoutAuthorship']
            ]
          ]
        ]
      ];
      $result = $this->elasticsearch->search($params);

      $spps= [];
      foreach($result['hits']['hits'] as $hit) {
        $spp = $hit['_source'];
        $spp['family']=strtoupper(trim($spp['family']));
        $spps[] = $spp;
      }

      if(count($spps) ==1){
        if($spps[0]['taxonomicStatus']=='accepted') {
          $occ['specie']=$spps[0];
        } else {
          $params=[
            'index'=>$this->db,
            'type'=>'taxon',
            'body'=>[
              'size'=> 9999,
              'query'=>[
                'bool'=>[
                  'must'=>[
                    [
                      'match'=>[
                        'taxonomicStatus'=>'accepted'
                      ]
                    ],
                    [
                      'match'=>[
                        'scientificNameWithoutAuthorshop'=>$spps[0]['acceptedNameUsage']
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ];
          $result = $this->elasticsearch->search($params);
          if(isset($result['hits']['hits'][0])) {
            $spp = $result['hits']['hits'][0]['_source'];
            $spp['family']=strtoupper(trim($spp['family']));
            $occ['specie']=$spp;
          }
        }
      } 
    }

    return $occ;
  }

  function flatten($occurrences) {
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
    return $occurrences;
  }
}
