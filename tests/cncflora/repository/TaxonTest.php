<?php

namespace cncflora\repository;

include_once 'vendor/autoload.php';

class TaxonTest extends \PHPUnit_Framework_TestCase {

    public static function setupBeforeClass() {
      \cncflora\Config::config();
      include __DIR__."/../../preload.php";
    }

    public function testFamilies() {
      $repo = new Taxon('test0');
      
      $families = $repo->listFamilies();
      $this->assertEquals(2,count($families));
      $this->assertEquals('ACANTHACEAE',$families[0]);
      $this->assertEquals('FABACEAE',$families[1]);
    }

    public function testFamily() {
      $repo = new Taxon('test0');
      
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
      $repo = new Taxon('test0');
      
      $spps = $repo->listNames('Aphelandra longiflora');
      $this->assertEquals(1,count($spps));
      $this->assertEquals('Aphelandra longiflora',$spps[0]);
      
      $spps = $repo->listNames('Vicia faba');
      $this->assertEquals(2,count($spps));
      $this->assertEquals('Vicia alba',$spps[0]);
      $this->assertEquals('Vicia faba',$spps[1]);
    }
}

