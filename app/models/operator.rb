# == Schema Information
# Schema version: 20100420165342
#
# Table name: operators
#
#  id         :integer         not null, primary key
#  code       :string(255)
#  name       :text
#  created_at :datetime
#  updated_at :datetime
#  short_name :string(255)
#

class Operator < ActiveRecord::Base
  has_many :route_operators
  has_many :routes, :through => :route_operator, :uniq => true
end
