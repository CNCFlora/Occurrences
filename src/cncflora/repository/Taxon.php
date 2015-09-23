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
        'query'=>[
          'match'=>[
            'taxonomicStatus'=>'accepted'
          ]
        ]
      ]
    ];
    $result = $this->elasticsearch->search($params);
    foreach($result['hits']['hits'] as $hit) {
      $families[]=strtoupper(trim($hit['_source']['family']));
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

    foreach($result['hits']['hits'] as $hit) {
      $spp = $hit['_source'];
      $spp['family']=strtoupper(trim($spp['family']));
      $spps[] = $spp;
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
    foreach($result['hits']['hits'] as $hit) {
      $names[]=trim($hit['_source']['scientificNameWithoutAuthorship']);
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
