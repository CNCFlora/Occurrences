<?php
session_start();

require __DIR__.'/../vendor/autoload.php';

$app = new cncflora\App();

$app->start();

