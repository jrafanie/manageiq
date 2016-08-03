module ControllerSpecHelper
  def assigns(key = nil)
    if key.nil?
      @controller.view_assigns.symbolize_keys
    else
      @controller.view_assigns[key.to_s]
    end
  end

  def set_user_privileges(user = FactoryGirl.create(:user_with_group))
    allow(User).to receive(:server_timezone).and_return("UTC")
    allow_any_instance_of(described_class).to receive(:set_user_time_zone)

    allow(controller).to receive(:check_privileges).and_return(true)
    login_as user
    allow(controller).to receive(:role_allows).and_return(true)
    allow(Rbac::Authorizer).to receive(:role_allows).and_return(true)
  end

  # Refactor these two methods, toss out stubbing we don't need
  def set_allowed_user_privileges
    user = FactoryGirl.create(:user_with_group)
    allow(User).to receive(:server_timezone).and_return("UTC")
    allow_any_instance_of(described_class).to receive(:set_user_time_zone)

    allow(controller).to receive(:check_privileges).and_return(true)
    login_as user
    allow(controller).to receive(:role_allows).and_return(true)

    # blindly mock all things that include ApplicationHelper to return true from role_allows
    # We should be able to get rid of lots of mocking if this thing works.
    ObjectSpace.each_object(ApplicationHelper) { |klass| allow(klass).to receive(:role_allows).and_return(true) }
    allow(Rbac::Authorizer).to receive(:role_allows).and_return(true)
  end

  def set_denied_user_privileges
    user = FactoryGirl.create(:user_with_group)
    allow(User).to receive(:server_timezone).and_return("UTC")
    allow_any_instance_of(described_class).to receive(:set_user_time_zone)

    allow(controller).to receive(:check_privileges).and_return(false)
    login_as user
    allow(controller).to receive(:role_allows).and_return(false)
    ObjectSpace.each_object(ApplicationHelper) { |klass| allow(klass).to receive(:role_allows).and_return(false) }

    allow(Rbac::Authorizer).to receive(:role_allows).and_return(false)
  end

  def setup_zone
    EvmSpecHelper.create_guid_miq_server_zone
  end

  shared_context "valid session" do
    let(:privilege_checker_service) { double("PrivilegeCheckerService", :valid_session?  => true) }

    before do
      allow(controller).to receive(:set_user_time_zone)
      allow(PrivilegeCheckerService).to receive(:new).and_return(privilege_checker_service)
    end
  end

  def seed_session_trees(a_controller, active_tree, node = nil)
    session[:sandboxes] = {
      a_controller => {
        :trees       => {
          active_tree => {}
        },
        :active_tree => active_tree
      }
    }
    session[:sandboxes][a_controller][:trees][active_tree][:active_node] = node unless node.nil?
  end
end
