<?php

namespace cncflora;

class App {

  private $router=null;

  function __construct() {
    Config::config();

    $r=new \Proton\Application;

    $r->get("/",'\cncflora\controller\Home::index');
    $r->post("/login",'\cncflora\controller\Home::login');
    $r->post("/logout",'\cncflora\controller\Home::logout');

    $this->router = $r;
  }

  function start() {
    $this->router->run();
  }
}

