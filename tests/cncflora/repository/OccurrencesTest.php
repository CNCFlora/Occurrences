<?php

namespace cncflora\repository;

include_once 'vendor/autoload.php';

class OccurrencesTest extends \PHPUnit_Framework_TestCase {

    public static function setupBeforeClass() {
      \cncflora\Config::config();
      include __DIR__."/../../preload.php";
    }

    public function testSearchUsesAllFields() {
      $repo = new Occurrences('test0');
      $occs = $repo->listOccurrences('Aphelandra longiflora');
      $this->assertEquals(5,count($occs));
    }

    public function testSearchUsesAllNames() {
      $repo = new Occurrences('test0');
      $occs = $repo->listOccurrences('Vicia faba');
      $this->assertEquals(2,count($occs));
    }

    public function testCRUD() {
      $repo = new Occurrences('test0');

      $newOcc = ['metadata'=>['type'=>'occurrence'],'scientificName'=>'Vicia faba'];
      $occ=$repo->insertOccurrence($newOcc);

      $this->assertNotNull($occ['metadata']['modified']);
      $this->assertEquals($occ['metadata']['modified'],$occ['metadata']['created']);

      $newOcc = ['metadata'=>['type'=>'occurrence'],'scientificName'=>'Vicia faba','institutionCode'=>'JBRJ','collectionCode'=>'RB','catalogNumber'=>'123'];
      $occ=$repo->insertOccurrence($newOcc);
      $this->assertEquals('urn:occurrence:JBRJ:RB:123',$occ['_id']);

      $occ['decimalLatitude']='10.10';
      $repo->updateoccurrence($occ);

      $occ = $repo->getOccurrence('urn:occurrence:JBRJ:RB:123');
      $this->assertEquals('10.10',$occ["decimalLatitude"]);

      $occs = $repo->listOccurrences('Vicia faba');
      $this->assertEquals(4,count($occs));
      $repo->deleteOccurrence($occ);
      $occ=$repo->getOccurrence('urn:occurrence:JBRJ:RB:123');
      $this->assertTrue($occ["deleted"]);
      $occs = $repo->listOccurrences('Vicia faba');
      $this->assertEquals(3,count($occs));
    }

    public function testBulk() {
      $repo = new Occurrences('test0');

      $occs =[
         ['scientificName'=>'vicia faba','occurrenceID'=>'123']
        ,['scientificName'=>'vicia alba','occurrenceID'=>'456']
      ];

      $repo->insertOccurrences($occs);

      $occ1=$repo->GetOccurrence('123');
      $this->assertEquals('vicia faba',$occ1["scientificName"]);
      $occ2=$repo->GetOccurrence('456');
      $this->assertEquals('vicia alba',$occ2["scientificName"]);

      $occ1['collector']='me';
      $occ2['collector']='you';

      $repo->updateOccurrences([$occ1,$occ2]);

      $occ1=$repo->GetOccurrence('123');
      $this->assertEquals('me',$occ1["collector"]);
      $occ2=$repo->GetOccurrence('456');
      $this->assertEquals('you',$occ2["collector"]);
    }

    public function testValidity() {
    }
}
