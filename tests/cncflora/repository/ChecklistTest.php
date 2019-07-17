<?php

namespace cncflora\repository;

include_once 'vendor/autoload.php';

use cncflora\Utils;

class ChecklistTest extends \PHPUnit_Framework_TestCase {

    public function setup() {
      \cncflora\Config::config();
      $client = \cncflora\Config::couchdb();
      $list = $client->getAllDatabases();

      foreach($list as $db) {
        $client->deleteDatabase($db);
      }
    }

    public function testListing() {
      $client = \cncflora\Config::couchdb();

      $client->createDatabase('test2');
      $client->createDatabase('test1');
      $client->createDatabase('test2_history');

      $repo = new Checklist();
      $list = $repo->getChecklists();

      $this->assertEquals(count($list),2);
      $this->assertEquals($list[0],'test1');
      $this->assertEquals($list[1],'test2');

    }

}

