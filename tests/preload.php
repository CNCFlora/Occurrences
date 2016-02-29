<?php

include_once __DIR__.'/../vendor/autoload.php';

$es = \cncflora\Config::elasticsearch();

$dbs =['test0','test1'];

foreach($dbs as $db) {
  try { $es->indices()->delete(['index'=>$db]); }
  catch(\Elasticsearch\Common\Exceptions\Missing404Exception $e) { }
  try { $es->indices()->create(['index'=>$db]); }
  catch(Exception $e) { }

  $couchdb = \cncflora\config::couchdb();
  try { $couchdb->deletedatabase($db); }
  catch(exception $e) { }
  try { $couchdb->createdatabase($db); }
  catch(exception $e) { }

  $couchdb = \cncflora\config::couchdb($db);

  $docs = json_decode(file_get_contents(__DIR__."/load.json"),true);

  foreach($docs as $doc) {
    $c=$couchdb->postDocument($doc);
    $a=$es->index([
      'index'=>$db,
      'type'=>$doc['metadata']['type'],
      'id'=>$doc['_id'],
      'body'=>$doc
    ]);
  }

}

sleep(1);

?>
