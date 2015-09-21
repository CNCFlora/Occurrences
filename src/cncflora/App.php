<?php

namespace cncflora;

Config::config();

$r=new \Proton\Application;

$r->get("/",'\cncflora\controller\Home::index');

$r->post("/login",'\cncflora\controller\Home::login');
$r->post("/logout",'\cncflora\controller\Home::logout');

$r->get("/{db}/families",'\cncflora\controller\Taxon::families');
$r->get("/{db}/family/{family}",'\cncflora\controller\Taxon::family');

$r->run();

