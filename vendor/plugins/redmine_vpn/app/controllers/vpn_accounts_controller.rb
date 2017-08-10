class VpnAccountsController < ApplicationController
  unloadable


  def index
    # 查询所有在有效期内，签发状态为"resumed"的签发记录
    @vpn_accounts = VpnAccount.find(:all, :conditions => ["status = ? AND resumed = ?", 'issued', 'N'])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @vpn_accounts }
    end
  end

  def add
    # 获取签发用户对象
    @user = User.find_by_id(params["user"]["id"])

    if @user.nil?
      flash[:error] = "被签发人员不能为空"
    else
      if VpnAccount.create_account(@user)
        flash[:notice] = l(:notice_successful_create)
      end
    end

    redirect_to :controller => 'vpn_accounts', :action => 'index'
  end

  def destroy
    # 获取删除VPN账户
    @vpn_account = VpnAccount.find(params[:id])
    @vpn_account.destroy_account

    flash[:notice] = l(:notice_successful_delete)

    redirect_to :controller => 'vpn_accounts', :action => 'index'
  end
end
