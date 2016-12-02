# tgn_uri is the uri from the Getty Thesaurus of Geographic Names
# geographic_term is the raw text entered and what is pared to get the tgn_uri
class AddGeographicToUsers < ActiveRecord::Migration
  def self.up
    change_table(:users) do |t|
      ## Database authenticatable
      t.string :tgn_uri
      t.string :geographic_term
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
  
end
