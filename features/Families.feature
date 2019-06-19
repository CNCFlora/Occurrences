Feature: Families and family
  In order to get to a specie
  As a user
  I need to see the families and its species

  Scenario: Family listing
    Given I am on "/test0/families"
    Then I should see "ACANTHACEAE"
    And I should see "FABACEAE"
    And I should not see "Leguminosa"

  Scenario: List species of family
    Given I am on "/test0/family/ACANTHACEAE"
    Then I should see "Aphelandra longiflora"
    And I should not see "Vicia"

  Scenario: List species another family, only accepted
    Given I am on "/test0/family/FABACEAE"
    Then I should not see "Aphelandra longiflora"
    And I should not see "Vicia alba"
    And I should see "Vicia faba"
    And I should see "Vicia outra"
