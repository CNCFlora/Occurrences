<?php

namespace cncflora\repository;

include_once 'vendor/autoload.php';

class TaxonTest extends \PHPUnit_Framework_TestCase {

    public static function setupBeforeClass() {
      \cncflora\Config::config();

      $es = \cncflora\Config::elasticsearch();
      try {
        $es->indices()->delete(['index'=>'test']);
      } catch(\Elasticsearch\Common\Exceptions\Missing404Exception $e) { }
      try {
        $es->indices()->create(['index'=>'test']);
      }catch(Exception $e) {
        vaR_dump($e);
      }

      $couchdb = \cncflora\Config::couchdb();
      try {
        $couchdb->deleteDatabase('test');
      } catch(Exception $e) { }
      try {
        $couchdb->createDatabase('test');
      } catch(Exception $e) {
        var_dump($e);
      }
      $couchdb = \cncflora\Config::couchdb('test');

      $docs = [
        [
          '_id'=>'t0'
          ,'metadata'=>['type'=>'taxon']
          ,'taxonomicStatus'=>'accepted'
          ,'family'=>'ACANTHACEAE'
          ,'scientificName'=>'Aphelandra longiflora S.Profice'
          ,'scientificNameWithoutAuthorship'=>'Aphelandra longiflora'
          ,'acceptedNameUsage'=>'Aphelandra longiflora S.Profice'
        ]
        ,[
          '_id'=>'t1'
          ,'metadata'=>['type'=>'taxon']
          ,'taxonomicStatus'=>'accepted'
          ,'family'=>'Fabaceae '
          ,'scientificName'=>'Vicia outra E.Dalcin'
          ,'scientificNameWithoutAuthorship'=>'Vicia outra'
          ,'acceptedNameUsage'=>'Vicia outra E.Dalcin'
        ]
        ,[
          '_id'=>'t2'
          ,'metadata'=>['type'=>'taxon']
          ,'taxonomicStatus'=>'accepted'
          ,'family'=>'FABACEAE'
          ,'scientificName'=>'Vicia faba E.Dalcin'
          ,'scientificNameWithoutAuthorship'=>'Vicia faba'
          ,'acceptedNameUsage'=>'Vicia faba E.Dalcin'
        ]
        ,[
          '_id'=>'t3'
          ,'metadata'=>['type'=>'taxon']
          ,'taxonomicStatus'=>'synonym'
          ,'family'=>'LEGUMINOSA'
          ,'scientificName'=>'Vicia alba E.Dalcin'
          ,'scientificNameWithoutAuthorship'=>'Vicia alba'
          ,'acceptedNameUsage'=>'Vicia faba E.Dalcin'
        ]
      ];
      $bulk = $couchdb->createBulkUpdater();
      $bulk->updateDocuments($docs);
      $be=$bulk->execute();

      foreach($docs as $doc) {
        $a=$es->index([
          'index'=>'test',
          'type'=>'taxon',
          'id'=>$doc['_id'],
          'body'=>$doc
        ]);
      }
      sleep(1);
    }

    public function testFamilies() {
      $repo = new Taxon('test');
      
      $families = $repo->listFamilies();
      $this->assertEquals(2,count($families));
      $this->assertEquals('ACANTHACEAE',$families[0]);
      $this->assertEquals('FABACEAE',$families[1]);
    }

    public function testFamily() {
      $repo = new Taxon('test');
      
      $spps = $repo->listFamily('ACANTHACEAE');
      $this->assertEquals(1,count($spps));
      $this->assertEquals('ACANTHACEAE',$spps[0]["family"]);
      $this->assertEquals('Aphelandra longiflora S.Profice',$spps[0]["scientificName"]);
      
      $spps = $repo->listFamily('FABACEAE');
      $this->assertEquals(2,count($spps));
      $this->assertEquals('FABACEAE',$spps[0]["family"]);
      $this->assertEquals('FABACEAE',$spps[1]["family"]);
      $this->assertEquals('Vicia faba E.Dalcin',$spps[0]["scientificName"]);
      $this->assertEquals('Vicia outra E.Dalcin',$spps[1]["scientificName"]);
    }

    public function testNames() {
      $repo = new Taxon('test');
      
      $spps = $repo->listNames('Aphelandra longiflora');
      $this->assertEquals(1,count($spps));
      $this->assertEquals('Aphelandra longiflora',$spps[0]);
      
      $spps = $repo->listNames('Vicia faba');
      $this->assertEquals(2,count($spps));
      $this->assertEquals('Vicia alba',$spps[0]);
      $this->assertEquals('Vicia faba',$spps[1]);
    }
}

