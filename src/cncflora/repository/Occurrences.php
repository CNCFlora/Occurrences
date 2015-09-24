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

  public function listOccurrences($name) {
    $names = (new Taxon($this->db))->listNames($name);

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

      $parts = explode(" ",$name);
      $params['body']['query']['bool']['should'][]
        = ['bool'=>['must'=>[['match'=>['genus'=>$parts[0]]],['match'=>['specificEpithet'=>$parts[1]]]]]];
    }

    $result = $this->elasticsearch->search($params);
    foreach($result['hits']['hits'] as $hit) {
      if(isset($hit['_source']['deleted'])) continue;
      $occs[]=$hit['_source'];
    }
    $occs=$this->prepareAll($occs);

    usort($occs,function($a,$b) { return strcmp($a['occurrenceID'],$b['occurrenceID']);});

    return $occs;
  }

  public function getOccurrence($id) {
    return $this->prepare($this->couchdb->findDocument($id)->body);
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
    $occurrence=$this->metalog($this->fix($occurrence));
    vaR_dump($occurrence);
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

    return $occurrences;
  }

  public function deleteOccurrence($occurrence){
    $occurrence['deleted']=true;
    $this->updateOccurrence($occurrence);
  }


  public function getStats($occurrences){
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
      'can_not_use'=>0
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

    $client = new \GuzzleHttp\Client();
    $res = $client->request('POST',DWC_SERVICES.'/api/v1/analysis/all',['json'=>$to_calc]);
    $calc = json_decode($res->getBody(),true);

    $stats['eoo']=$calc['eoo']['all']['area'];
    $stats['aoo']=$calc['aoo']['all']['area'];

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

  public function prepareAll($docs) {
    $docs=$this->fixAll($docs);

    foreach($docs as $i=>$doc) {
      $docs[$i] = $this->prepare($doc,false);
    }

    return $docs;
  }

  public function fix($doc) {
    $client = new \GuzzleHttp\Client();
    $res = $client->request('POST',DWC_SERVICES.'/api/v1/fix',[
      'json'=>[$doc]]);
    $redoc = json_decode($res->getBody(),true);
    foreach($redoc[0] as $k=>$v) {
      $doc[$k] = $v;
    }

    foreach($doc['validation'] as $k=>$v) {
      if(strpos($k,'-') >0) {
        unset($doc['validation'][$k]);
      }
    }

    return $doc;
  }
  public function prepare($doc,$dwc=true) {
    if($dwc) {
      $doc=$this->fixRaw($doc);
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

    if(isset($doc["validation"])) {
      if(is_array($doc["validation"])) {
        foreach($doc["validation"] as $k=>$v) {
          $kk = $k."-".$v;
          $doc['validation'][$kk]=$v;
        }

        if(isset($doc["validation"]["status"])) {
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
}
