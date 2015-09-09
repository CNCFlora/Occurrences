<?php

namespace cncflora;

use Symfony\Component\Yaml\Yaml;

class Config {

  public static $configured;
  public static $config;

  public static function config() {
    if(self::$configured) return;
    self::$config=new Config;

    $raw = Yaml::parse(file_get_contents( __DIR__."/../../config/settings.yml" ));
    
    if(!defined('ENV')) {
      $env = getenv("PHP_ENV");
      if($env == null) {
        $env = 'development';
      }
      define('ENV',$env);
    }

    $data=$raw[$env];

    foreach($data as $key=>$value) {
      preg_match_all('/\$([a-zA-Z]+)/',$value,$reg);
      if(count($reg[0]) >= 1) {
        $e = getenv($reg[1][0]);
        $data[$key] = str_replace($reg[0][0],$e,$value);
      }
    }

    if(!isset($data['base'])) $data['base'] = '';
    if(!isset($data['lang'])) $data['lang'] = 'pt';

    foreach($data as $k=>$v) {
      if(!defined($k)) {
        define(strtoupper($k),$v);
        self::$config->$k=$v;
      }
    }

    self::$config->strings = json_decode(file_get_contents(__DIR__."/../../resources/locales/".LANG.".json"));

    self::$configured=true;
  }
}

