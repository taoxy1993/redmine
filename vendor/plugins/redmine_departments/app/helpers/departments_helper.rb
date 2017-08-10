module DepartmentsHelper

  def group_settings_tabs
    tabs = [{:name => 'general', :partial => 'departments/general', :label => :label_general},
            {:name => 'users', :partial => 'departments/users', :label => :label_user_plural}]
  end

  def parent_department_div_tag(departments)
    s = ''
    department_tree(departments) do |department, level|
      # s << content_tag(:ul) do
      #   content_tag(:li, department)
      # end
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      s << content_tag(:div, name_prefix + h(department))
    end
    s
  end

  def parent_department_select_tag(department)
    selected = department.parent
    # retrieve the requested parent department
    parent_id = (params[:department] && params[:department][:parent_id]) || params[:parent_id]
    if parent_id
      selected = (parent_id.blank? ? nil : Department.find(parent_id))
    end

    options = ''
    options << "<option value=''></option>" if department.allowed_parents.include?(nil)
    options << department_tree_options_for_select(department.allowed_parents.compact, :selected => selected)
    content_tag('select', options, :name => 'department[parent_id]', :id => 'department_parent_id')
  end

  def department_tree_options_for_select(departments, options = {})
    s = ''
    department_tree(departments) do |department, level|
      name_prefix = (level > 0 ? ('&nbsp;' * 2 * level + '&#187; ') : '')
      tag_options = {:value => department.id}
      if department == options[:selected] || (options[:selected].respond_to?(:include?) && options[:selected].include?(department))
        tag_options[:selected] = 'selected'
      else
        tag_options[:selected] = nil
      end
      tag_options.merge!(yield(department)) if block_given?
      s << content_tag('option', name_prefix + h(department), tag_options)
    end
    s
  end

  # Renders a tree of departments as a nested set of unordered lists
  # The given collection may be a subset of the whole department tree
  # (eg. some intermediate nodes are private and can not be seen)
  def render_department_hierarchy(departments)
    s = ''
    if departments.any?
      ancestors = []
      original_department = @department
      departments.each do |department|
        manager = department.manager
        # set the department environment to please macros.
        @department = department
        if (ancestors.empty? || department.is_descendant_of?(ancestors.last))
          s << "<ul id='organization'>\n"
        else
          ancestors.pop
          s << "</li>"
          while (ancestors.any? && !department.is_descendant_of?(ancestors.last))
            ancestors.pop
            s << "</ul></li>\n"
          end
        end
        s << "<li>"
        s<<"<div>"
        s<<"<p>"+link_to(h(department), {:controller => "departments", :action => "show", :id => department}) +"</p>"
        s<<"<p><"+link_to(manager, :controller => 'users', :action => 'show', :id => manager)+"></p>"
        # s<<"<p>负责人："+link_to(manager, :controller => 'users', :action => 'show', :id => manager)+"</p>"
        s << "</div>\n"
        ancestors << department
      end
      s << ("</li></ul>\n" * ancestors.size)
      @department = original_department
    end
    s
  end

  # Yields the given block for each department with its level in the tree
  def department_tree(departments, &block)
    ancestors = []
    departments.sort_by(&:lft).each do |department|
      while (ancestors.any? && !department.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield department, ancestors.size
      ancestors << department
    end
  end

  # Generates a link to a department if active
  # Examples:
  #
  #   link_to_department(department)                          # => link to the specified department overview
  #   link_to_department(department, :action=>'settings')     # => link to department settings
  #   link_to_department(department, {:only_path => false}, :class => "department") # => 3rd arg adds html options
  #   link_to_department(department, {}, :class => "department") # => html options with default url (department overview)
  #
  def link_to_department(department, options={}, html_options = nil)
    if department.active?
      url = {:controller => 'departments', :action => 'show', :id => department}.merge(options)
      link_to(h(department), url, html_options)
    else
      h(department)
    end
  end
end
