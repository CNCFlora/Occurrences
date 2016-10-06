<?php

namespace cncflora\controller;

use \cncflora\View;

class Taxon {

  public function families($request,$response,$args) {
    $db = $args['db'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);
    $families = $repo->listFamilies();

    $fs=[];
    foreach($families as $f) {
      $spps = $repo->listFamily($f);
      $names = [];
      foreach($spps as $spp) {
        $names = array_merge($names,$repo->listNames($spp['scientificNameWithoutAuthorship']));
      }
      $occs =  $repoOcc->listOccurrences($names,false);

      $stats = $repoOcc->getStats($occs,false);
      $stats['family']=$f;
      $fs[]=$stats;
    }
    $response->setContent(new View('families',['db'=>$db,'families'=>$fs]));
    return $response;
  }

  public function family($req,$res,$args){
    $db = $args['db'];
    $family = $args['family'];
    $repo = new \cncflora\repository\Taxon($db);
    $repoOcc = new \cncflora\repository\Occurrences($db);

    $spps = $repo->listFamily($family);

    foreach($spps as $i=>$spp) {
       $occs = $repoOcc->listOccurrences($spp['scientificNameWithoutAuthorship'],false);
       $currentTaxon = $this->getCurrentTaxon($db, $spp['scientificNameWithoutAuthorship']);
       $taxonomia_diferente = ($currentTaxon->scientificNameWithoutAuthorship != $spp['scientificNameWithoutAuthorship']);
       $spp['taxonomia_diferente'] = $taxonomia_diferente;
       $spp['taxonomia_diferente_scientificNameWithoutAuthorship'] = $currentTaxon->scientificNameWithoutAuthorship;
       $spp['taxonomia_diferente_scientificNameAuthorship'] = $currentTaxon->scientificNameAuthorship;
       $spp['taxonomia_diferente_scientificName'] = $currentTaxon->scientificNameWithoutAuthorship . ';' . $currentTaxon->scientificNameAuthorship;
       $spps[$i] = array_merge($spp,$repoOcc->getStats($occs,false));
    }

    usort($spps,function($s0,$s1){
      return strcmp(trim(strtolower($s0['scientificNameWithoutAuthorship'])),trim(strtolower($s1['scientificNameWithoutAuthorship'])));
    });

    $res->setContent(new View('family',['db'=>$db,'species'=>$spps,'family'=>$family]));
    return $res;
  }

  public function getCurrentTaxon($db, $name) {
    $name = trim($name);
    $flora = json_decode(file_get_contents(FLORADATA."/api/v1/specie?scientificName=".rawurlencode($name)))->result;

    if($flora==null) {
      $flora = ["not_found"=>true];
    } else if($flora->scientificNameWithoutAuthorship != $name) {
      $flora->changed=true;
    } else {
      $syns = $this->getSynonyms($db, $name);
      $floraSyns = $flora->synonyms;

      $synsNames = [];
      foreach($syns as $syn) {
        $synsNames[] = $syn->scientificNameWithoutAuthorship;
      }
      sort($synsNames);

      $floraSynsNames =[];
      foreach($floraSyns as $syn) {
        $floraSynsNames[] = $syn->scientificNameWithoutAuthorship;
      }
      sort($floraSynsNames);

      if(implode(",",$floraSynsNames) != implode(",",$synsNames)) {
          $flora->synonyms_changed=true;
      }
    }

    return $flora;
  }

  public function getSynonyms($db, $name) {
    $response = $this->searchRaw($db, "taxon","taxonomicStatus:\"synonym\" AND acceptedNameUsage:\"".$name."*\"");
    $taxons = array();
    foreach($response as $row) {
        $row->family = strtoupper($row->family);
        $taxons[] = $row;
    }
    return $taxons;
}

    public function searchRaw($db,$idx,$q) {
        $q = str_replace("=",":",$q);
        $url = ELASTICSEARCH.'/'.$db.'/'.$idx.'/_search?size=99999&q='.urlencode($q);
        $r = json_decode(file_get_contents($url));
        $arr =array();
        $ids = [];
        foreach($r->hits->hits as $hit) {
            $doc = $hit->_source;
            $doc->_id = $doc->id;
            if(isset($doc->rev)) {
              $doc->_rev = $doc->rev;
              unset($doc->rev);
            }
            unset($doc->id);
            $arr[] = $doc;
        }

        return $arr;
    }

}
