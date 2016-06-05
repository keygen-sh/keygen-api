module AccessControl
  extend ActiveSupport::Concern

  include ActionController::HttpAuthentication::Token::ControllerMethods

  included do
    before_action :authenticate_with_token
  end

  class_methods do

    def accessible_by_architect(*actions)
      before_action -> {
        @current_user.architect? || render_unauthorized
      }, only: actions
    end

    def accessible_by_admin(*actions)
      before_action -> {
        @current_user.admin? || render_unauthorized
      }, only: actions
    end

    def accessible_by_admin_or_owner(*actions)
      before_action -> {
        # Get class name of access-controlled resource
        resource_class = controller_name.classify.constantize
        # Get name of singular resource
        resource_name = controller_name.singularize
        # Get instance variable set by resource controller, e.g. set_user => @user
        resource = instance_variable_get "@#{resource_name}"
        # Get id of user directly or through the resource owned by the user
        owner_id = if resource_class == User
                     params[:id]
                   else
                     resource.user.try(:hashid)
                   end

        @current_user.admin? || @current_user.hashid == owner_id ||
          render_unauthorized
      }, only: actions
    end
  end

  private

  def authenticate_with_token
    authenticate_with_http_token do |token, options|
      @current_user = @current_account.users.find_by auth_token: token
    end
  end
end
