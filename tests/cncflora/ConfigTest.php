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
    }

}

