<?php

namespace cncflora;

class App {

  private $router=null;

  function __construct() {
    Config::config();

    $r=new \Proton\Application;

    $r->get("/",function($req,$res) {
      $res->setContent('Hello, world!');
      return $res;
    });

    $this->router = $r;
  }

  function start() {
    $this->router->run();
  }
}

