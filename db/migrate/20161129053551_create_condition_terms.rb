# Adds terms for the user condition.
# The "entered_term" is the raw term they put in (like "Heart Attack")
# The "uri" is the MeSH linked data uri for that term
class CreateConditionTerms < ActiveRecord::Migration
  def self.up
    create_table :condition_terms do |t|
      t.references :user, index: true, foreign_key: true
      t.string :concept_uri, index: true
    end
  end

  def self.down
    drop_table :condition_terms
  end
  
end
