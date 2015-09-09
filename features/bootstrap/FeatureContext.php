<?php
putenv("PHP_ENV=test");

include __DIR__.'/../../vendor/autoload.php';

use Behat\Behat\Context\ClosuredContextInterface,
    Behat\Behat\Context\TranslatedContextInterface,
    Behat\Behat\Context\BehatContext,
    Behat\Behat\Exception\PendingException;

use Behat\Gherkin\Node\PyStringNode,
    Behat\Gherkin\Node\TableNode;

use Behat\MinkExtension\Context\MinkContext;

class FeatureContext extends MinkContext {

    /** @BeforeFeature */
    public static function prepareForTheFeature(){
      // setup
    }

    /**
     * @When /^I click on "([^"]*)"$/
     */
    public function iClickOn($selector) {
        $this->getMainContext()->getSession()->getPage()->find('css',$selector)->click();
    }

    /**
     * @Then /^I logout$/
     */
    public function iLogout() {
        $this->getMainContext()->getSession()->executeScript('$.post("/logout","",function(){})');
        $this->getSession()->wait(500);
        $this->getMainContext()->getSession()->reload();
    }

    /**
     * @Then /^I login as "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)"$/
     */
    public function iLoginAs($name,$email,$ctx,$roles) {
        $this->iLogout();
        $doc = ['name'=>$name,'email'=>$email,'roles'=>[['context'=>$ctx,'roles'=>[]]]];
        $roles = explode(",",$roles);
        foreach($roles as $role) {
            $doc['roles'][0]['roles'][] = ['role'=>$role,'entities'=>[]];
        }
        $this->getMainContext()->getSession()->executeScript('$.post("/login",JSON.stringify('.json_encode($doc).'),function(){})');
        $this->getMainContext()->getSession()->wait(1500);
        $this->getMainContext()->getSession()->reload();
    }

    /**
     * @Then /^I login as "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)", "([^"]*)"$/
     */
    public function iLoginAs2($name,$email,$ctx,$roles,$ents) {
        $this->iLogout();
        $doc = ['name'=>$name,'email'=>$email,'roles'=>[['context'=>$ctx,'roles'=>[]]]];
        $roles = explode(",",$roles);
        $ents  = explode(",",$ents);
        foreach($roles as $role) {
            $doc['roles'][0]['roles'][] =  ['role'=>$role,'entities'=>$ents] ;
        }
        $this->getMainContext()->getSession()->executeScript('$.post("/login",JSON.stringify('.json_encode($doc).'),function(){})');
        $this->getMainContext()->getSession()->wait(1500);
        $this->getMainContext()->getSession()->reload();
    }

    /**
     * @Given /^I save the page "([^"]*)"$/
     */
    public function iSaveThePage($name) {
        file_put_contents($name,$this->getMainContext()->getSession()->getPage()->getHtml());
    }

    /**
     * @Then /^I wait (\d+)$/
     */
    public function iWait($t) {
        $this->getMainContext()->getSession()->wait((int)$t);
    }

    /**
     * @Then /^I fill field "([^"]+)" with "([^"]+)"$/
     */
    public function iFillField($sel,$text) {
        $this->getMainContext()->getSession()->executeScript('$("'.$sel.'").val("'.$text.'")');
    }
}

