<?php

namespace cncflora;

Config::config();

$r=new \Proton\Application;

$r->get("/",'\cncflora\controller\Home::index');

$r->post("/login",'\cncflora\controller\Home::login');
$r->post("/logout",'\cncflora\controller\Home::logout');

$r->get("/{db}/families",'\cncflora\controller\Taxon::families');
$r->get("/{db}/family/{family}",'\cncflora\controller\Taxon::family');

$r->get("/{db}/specie/{name}",'\cncflora\controller\Occurrences::specie');
$r->get("/{db}/specie/{name}/raw",'\cncflora\controller\Occurrences::occurrences');
$r->get("/{db}/specie/{name}/calcs",'\cncflora\controller\Occurrences::calcs');

$r->post("/{db}/occurrence/{id}/analysis",'\cncflora\controller\Occurrences::analysis');
$r->post("/{db}/occurrence/{id}/validate",'\cncflora\controller\Occurrences::validate');
$r->post("/{db}/occurrence/{id}/sig",'\cncflora\controller\Occurrences::sig');

$r->subscribe('request.received', function ($evt,$req) use ($r){
  $uri = explode("?",$req->getRequestURI())[0];
  if(isset($_SESSION['logged']) && $_SESSION['logged'] === true) {
    if(isset($_GET['back_to'])) {
      header('Location: '.$_GET['back_to']);
      exit;
    }
  } else if($uri != "" && $uri != "/" && $uri != "/login" && $uri != "/logout") {
    /*
    $res = new \Symfony\Component\HttpFoundation\Response;
    $res->setStatusCode(303);
    $res->headers->add(['Location'=>'/?back_to='.$req->getURI()]);
    $r->terminate($req,$res);
    */
    header('Location: '.BASE.'/?back_to='.$req->getURI());
    exit;
    //return $res;
  }
});

$r->run();

