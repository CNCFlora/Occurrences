<?php

namespace cncflora;

class View {

  public $file ;
  public $props ;

  public static $defaults ;

  function __construct($file,$props=null) {
    $this->template = file_get_contents(__DIR__."/../../resources/templates/".$file.".html");

    if(is_array($props)) $this->props = $props ;
    else if(is_object($props)) $this->props = (array) $props;
    else $this->props = array();

    $cfg = Config::$config;
    foreach($cfg as $k=>$v) {
      $this->props[$k] =$v;
    }

    if(isset($this->props['db'])) {
      $this->props['db_name']=strtoupper( str_replace("_"," ", $this->props['db']) );
    }

    $iterator = new \DirectoryIterator(__DIR__."/../../resources/templates");
    foreach ($iterator as $file) {
      if($file->isFile() && preg_match("/\.html$/",$file->getFilename())) {
        $this->partials[substr( $file->getFilename(),0,-5)] = file_get_contents($file->getPath()."/".$file->getFilename());
      }
    }
  }

  function __toString() {
      $props = array_merge($_SESSION,$this->props);
      $props['strings_json'] = json_encode($props['strings']);

      if(isset( $_SESSION['logged'] ) && $_SESSION['logged'] ===true) {
        $props['user_json'] = json_encode($_SESSION['user']);
      }

      $m = new \Mustache_Engine(array('partials'=>$this->partials));
      $content = $m->render($this->template,$props);

      return $content;
  }

}
