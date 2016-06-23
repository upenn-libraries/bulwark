require 'faker'

FactoryGirl.define do

  factory :version_control_agent do |f|
    f.association :repo
    f.vc_type "GitAnnex"
  end

end
