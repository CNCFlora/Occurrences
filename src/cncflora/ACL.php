<?php

namespace cncflora;

class ACL {

  public static function listPermissions($user,$db,$specie){

    $sig=false;
    $analysis=false;
    $validate=false;

    foreach($user->roles as $role) {
      if(strtolower($role->context) == strtolower($db) ) {
        foreach($role->roles as $sub_role) {
          if(strtolower($sub_role->role) == 'sig') {
            $sig=true;
          } else if(strtolower($sub_role->role) == 'analyst') {
            foreach($sub_role->entities as $ent) {
              $ent = strtolower($ent);
              if($ent == 'all'
                || $ent == strtolower($specie['family'])
                || $ent == strtolower($specie['scientificNameWithoutAuthorship'])) {
                $analysis=true;
              }
            }
          } else if(strtolower($sub_role->role) == 'validator') {
            foreach($sub_role->entities as $ent) {
              $ent = strtolower($ent);
              if($ent == 'all'
                || $ent == strtolower($specie['family'])
                || $ent == strtolower($specie['scientificNameWithoutAuthorship'])) {
                $validate=true;
              }
            }
          }
        }
      }
    }

    return [$sig,$analysis,$validate];
  }
}
