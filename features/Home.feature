Feature: Homepage
  In order to start using the app
  As a user
  I need to login and pick a checklist

  Scenario: Non logged user
    Given I am on "/"
    Then I logout
    Then I should see "Login"
    And I should not see "Logout"
    And I should not see "Workflow"
    And I should see "Faça login para começar."

  Scenario: I can login and see the checklists
    Given I am on "/"
    Then I login as "Diogo", "diogo@diogok.net", "TEST0", "admin"
    Then I should see "Logout"
    And I should not see "Login"
    And I should see "Bem vindo, Diogo."
    Then I reload the page
    And I should see "Bem vindo, Diogo."
    And I should see "TEST1"
    And I should see "TEST2"

