class ConditionTerm < ApplicationRecord
  belongs_to :user

  # Method added by Blacklight; Blacklight uses #to_s on your
  # user class to get a user-displayable login/identifier for
  # the account.
  def to_s
    entered_term
  end


end
