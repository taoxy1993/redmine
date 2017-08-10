class CategorysController < ApplicationController
  unloadable

  helper :sort
  include SortHelper
  include CategorysHelper

  helper_method :find_project_manager

  # 按部门查询sql语句
  @@sql_department = "select projects.id as dep_id, projects.`name` as dep_name
from projects
  left join members on members.project_id = projects.id
  left join member_roles on member_roles.member_id = members.id
  left join roles on roles.id = member_roles.role_id
  left join users on users.id = members.user_id and (users.type = 'User' or users.type = 'AnonymousUser')
  left join custom_values on custom_values.customized_id = projects.id
  left join custom_fields on custom_fields.id = custom_values.custom_field_id
where `custom_values`.customized_type = 'Project'
  and `custom_values`.`value` = '部门日常工作'"

  # 按产品查询sql语句
  @@sql_product = "select projects.id as proj_id, custom_values.`value` as product_name, projects.name as proj_name
from projects
  left join members on members.project_id = projects.id
  left join member_roles on member_roles.member_id = members.id
  left join roles on roles.id = member_roles.role_id
  left join users on users.id = members.user_id and (users.type = 'User' or users.type = 'AnonymousUser')
  left join custom_values on custom_values.customized_id = projects.id
  left join custom_fields on custom_fields.id = custom_values.custom_field_id
where `custom_values`.customized_type = 'Project'
  and `custom_fields`.`name` = '产品名称'
  and `custom_values`.`value` <> '非产品'"

  # 按项目查询sql语句
  @@sql_project = "select projects.id as proj_id, projects.name as proj_name
from projects
  left join members on members.project_id = projects.id
  left join member_roles on member_roles.member_id = members.id
  left join roles on roles.id = member_roles.role_id
  left join users on users.id = members.user_id and (users.type = 'User' or users.type = 'AnonymousUser')
  left join custom_values on custom_values.customized_id = projects.id
  left join custom_fields on custom_fields.id = custom_values.custom_field_id
where `custom_values`.customized_type = 'Project'
  and `custom_values`.`value` = '产品项目'"

  # group by语句
  @@sql_group_by = "group by projects.id"

  # order by语句
  # @@sql_order_by = "order by "

  def index
    name = ""
    unless params[:name].blank?
      name = params[:name].strip.downcase
    end

    @user = User.current
    @departments = find_departments(@user, name)

    respond_to do |format|
      format.html { render :template => 'categorys/index.html.erb', :layout => !request.xhr? }
      format.csv  { send_data(department_export_to_csv(@departments),
                              :type => 'text/csv; charset=iso-8859-1; header=present',
                              :disposition => 'attachment; filename=export.csv') }
    end
  end

  def index_cp
    name = ""
    unless params[:name].blank?
      name = params[:name].strip.downcase
    end

    @user = User.current
    @products = find_products(@user, name)

    respond_to do |format|
      format.html { render :template => 'categorys/index_cp.html.erb', :layout => !request.xhr? }
      format.csv  { send_data(product_export_to_csv(@products),
                              :type => 'text/csv; charset=iso-8859-1; header=present',
                              :filename => 'export.csv') }
    end
  end

  def index_xm
    name = ""
    unless params[:name].blank?
      name = params[:name].strip.downcase
    end

    @user = User.current
    @projects = find_projects(@user, name)

    respond_to do |format|
      format.html { render :template => 'categorys/index_xm.html.erb', :layout => !request.xhr? }
      format.csv  { send_data(project_export_to_csv(@projects),
                              :type => 'text/csv; charset=iso-8859-1; header=present',
                              :filename => 'export.csv') }
    end
  end

=begin
    查询部门
=end
  def find_departments(user, name)
    sort_init 'dep_name', 'asc'
    sort_update %w(dep_name)
    @@sql_order_by = "order by " + sort_clause

    @@sql_like = "and projects.`name` like '%#{name}%'"

    if user.admin?
      @departments = Project.find_by_sql(@@sql_department + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    else
      @@sql_where = "and users.id = #{user.id}"
      @departments = Project.find_by_sql(@@sql_department + " " + @@sql_where + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    end

    @departments
  end

=begin
查询产品
=end
  def find_products(user, name)
    sort_init 'product_name', 'asc'
    sort_update %w(product_name proj_name)
    @@sql_order_by = "order by " + sort_clause

    @@sql_like = "and projects.`name` like '%#{name}%'"

    if user.admin?
      @products = Project.find_by_sql(@@sql_product + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    else
      @@sql_where = "and users.id = #{user.id}"
      @products = Project.find_by_sql(@@sql_product + " " + @@sql_where + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    end

    @products
  end

=begin
查询项目
=end
  def find_projects(user, name)
    sort_init 'proj_name', 'asc'
    sort_update %w(proj_name)
    @@sql_order_by = "order by " + sort_clause

    @@sql_like = "and projects.`name` like '%#{name}%'"

    if user.admin?
      @projects = Project.find_by_sql(@@sql_project + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    else
      @@sql_where = "and users.id = #{user.id}"
      @projects = Project.find_by_sql(@@sql_project + " " + @@sql_where + " " + @@sql_like + " " + @@sql_group_by + " " + @@sql_order_by);
    end

    @projects
  end

=begin
查询项目经理
=end
  def find_project_manager(project_id, role_name)
    sql = "select IFNULL(GROUP_CONCAT(users.lastname, users.firstname),'无') as dep_manager
from projects
	left join members on members.project_id = projects.id
	left join member_roles on member_roles.member_id = members.id
	left join roles on roles.id = member_roles.role_id
	left join users on users.id = members.user_id and (users.type = 'User' or users.type = 'AnonymousUser')
where (roles.`name` = '#{role_name}' or ISNULL(roles.`name`) = true)
	and projects.id = #{project_id}
group by projects.id"

    @departments = Project.find_by_sql(sql)
    manager_name = ""

    @departments.each do |department|
      manager_name = department.dep_manager
    end

    return manager_name

  end
end