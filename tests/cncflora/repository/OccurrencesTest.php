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
      
    }
}
