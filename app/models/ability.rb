class Ability
  include Hydra::Ability
  def custom_permissions
    if current_user.admin?
      binding.pry()
      can [:create, :edit, :add_user, :remove_user], Role
      can [:create, :edit, :update], Manuscript
    end
  end
end
