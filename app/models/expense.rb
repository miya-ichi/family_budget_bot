class Expense < ApplicationRecord
  validates :name, presence: true
  validates :cost, presence: true
  validates :line_user_id, presence: true
end
