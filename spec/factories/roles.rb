FactoryGirl.define do
  factory :role do
    resource nil
    user { FactoryGirl.create(:user) }
    role 'admin'
  end
end
