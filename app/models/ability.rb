class Ability
  include Hydra::Ability
  def custom_permissions
    if current_user.admin?
       can [:create, :edit, :add_user, :remove_user], ActiveFedora::Base
     end
  end
end
