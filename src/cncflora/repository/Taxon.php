<?php

namespace cncflora\repository;

class Taxon {

  public $couchdb = null;
  public $db = null;
  public $elasticsearch=null;

  public function __construct($db) {
    $this->db=$db;
    $this->couchdb = \cncflora\Config::couchdb($db);
    $this->elasticsearch = \cncflora\Config::elasticsearch();
  }

  public function listFamilies(){
    $families=[];

    $params=[
      'index'=>$this->db,
      'type'=>'taxon',
      'body'=>[
        'size'=> 9999,
        'query'=>[
          'match'=>[
            'taxonomicStatus'=>'accepted'
          ]
        ]
      ]
    ];
    $result = $this->elasticsearch->search($params);
    foreach($result['hits']['hits'] as $hit) {
      $f = strtoupper(trim($hit['_source']['family']));
      if(strlen($f) >3) {
      $families[]=$f;
      }
    }
    sort($families);
    $families=array_unique($families);

    return $families;
  }

  public function listFamily($family) {
    $spps=[];

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
                  'family'=>trim($family)
                ]
              ]
            ]
          ]
        ]
      ]
    ];
    $result = $this->elasticsearch->search($params);

    $got=[];
    foreach($result['hits']['hits'] as $hit) {
      $spp = $hit['_source'];
      $spp['family']=strtoupper(trim($spp['family']));
      if(!isset($got[$spp['scientificNameWithoutAuthorship']])) {
        $spps[] = $spp;
        $got[$spp['scientificNameWithoutAuthorship']]=true;
      }
    }

    usort($spps,function($a,$b){
      return strcmp($a['scientificName'],$b['scientificName']);
    });

    return $spps;
  }

  public function listNames($spp) {
    $names=[];

    $params=[
      'index'=>$this->db,
      'type'=>'taxon',
      'body'=>[
        'size'=> 9999,
        'query'=>[
          'match'=>[
          'acceptedNameUsage'=>[
              'query'=>$spp
              ,'operator'=>'and'
            ]
          ]
        ]
      ]
    ];
    $result = $this->elasticsearch->search($params);
    $got=[];
    foreach($result['hits']['hits'] as $hit) {
      $name = trim($hit['_source']['scientificNameWithoutAuthorship']);
      if(!isset($got[$name])) {
        $names[]=$name;
        $got[$name]=true;
      }
    }
    sort($names);
    $names=array_unique($names);

    return $names;
  }

  public function getSpecie($name) {
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
                'acceptedNameUsage'=>[
                    'query'=>$name ,'operator'=>'and'
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ];
    $result = $this->elasticsearch->search($params);

    return $result['hits']['hits'][0]['_source'];
  }
}
