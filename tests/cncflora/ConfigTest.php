<?php

namespace cncflora;

include_once 'vendor/autoload.php';

class ConfigTest extends \PHPUnit_Framework_TestCase {

    public function setup() {
      putenv("PHP_ENV=test");
    }

    public function tearDown() {
    }

    public function testConfig() {
        Config::config();
        $this->assertEquals(ENV,"test");
        $this->assertEquals(Config::$_couchdb['host'],'couchdb');
        $this->assertEquals(Config::$_couchdb['port'],'5984');

        $client = Config::couchdb();
        $this->assertEquals($client,$client);

        $client = Config::couchdb('db');
        $this->assertEquals($client,$client);

        $client = Config::elasticsearch();
        $this->assertEquals($client,$client);
    }

}

