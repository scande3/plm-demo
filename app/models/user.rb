class User < ApplicationRecord
  has_many :condition_terms, :dependent => :destroy

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :email, :password, :password_confirmation
  end
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    email
  end

  def indexer
    @indexer ||= UserIndexer.new
  end

  def save(*)
    super
    indexer.to_solr(self) unless self.guest
  end

  def save!(*)
    super
    indexer.to_solr(self) unless self.guest
  end

  def condition_term_lookup
    self.condition_terms.map {|c| c.concept_uri }
  end


end
