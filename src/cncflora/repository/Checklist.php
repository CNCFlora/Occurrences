<?php

namespace cncflora\repository;

class Checklist {

  public $couchdb;

  public function __construct() {
    $this->couchdb = \cncflora\Config::couchdb();
  }

  public function getChecklists() {
    $dbs=[];

    $list = $this->couchdb->getAllDatabases();
    foreach($list as $db) {
      if(!preg_match("/^_/",$db) && !preg_match("/_history$/",$db)) {
        $dbs[] = $db;
      }
    }
    sort($dbs);

    return $dbs;
  }
}
