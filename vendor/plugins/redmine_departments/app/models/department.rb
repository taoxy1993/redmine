class Department < ActiveRecord::Base
  unloadable

  belongs_to :manager, :class_name => 'User', :foreign_key => 'manager_id'
  belongs_to :sub_manager, :class_name => 'User', :foreign_key => 'sub_manager_id'
  belongs_to :parent, :class_name => 'Department', :foreign_key => 'parent_id'

  has_many :department_users, :dependent => :destroy
  has_many :users, :through => :department_users

  acts_as_nested_set :order => 'name'

  validates_presence_of :name, :manager_id, :rank
  validates_length_of :name, :maximum => 30
  validates_length_of :description, :maximum => 255

  named_scope :visible

  def to_s
    name.to_s
  end

  def user_added(user)

  end

  def user_removed(user)

  end

  def css_classes
    s = 'project'
    s << ' root' if root?
    s << ' child' if child?
    s << (leaf? ? ' leaf' : ' parent')
    s
  end

  # Returns an array of departments the department can be moved to
  # by the current user
  def allowed_parents
    return @allowed_parents if @allowed_parents
    @allowed_parents = Department.find(:all)
    @allowed_parents = @allowed_parents - self_and_descendants
    if User.current.allowed_to?(:add_department, nil, :global => true) || (!new_record? && parent.nil?)
      @allowed_parents << nil
    end
    unless parent.nil? || @allowed_parents.empty? || @allowed_parents.include?(parent)
      @allowed_parents << parent
    end
    @allowed_parents
  end

  # Sets the parent of the department with authorization check
  def set_allowed_parent!(p)
    unless p.nil? || p.is_a?(Department)
      if p.to_s.blank?
        p = nil
      else
        p = Department.find_by_id(p)
        return false unless p
      end
    end
    if p.nil?
      if !new_record? && allowed_parents.empty?
        return false
      end
    elsif !allowed_parents.include?(p)
      return false
    end
    set_parent!(p)
  end

  # Sets the parent of the department
  # Argument can be either a Department, a String, a Fixnum or nil
  def set_parent!(p)
    unless p.nil? || p.is_a?(Department)
      if p.to_s.blank?
        p = nil
      else
        p = Department.find_by_id(p)
        return false unless p
      end
    end
    if p == parent && !p.nil?
      # Nothing to do
      true
    elsif p.nil? || move_possible?(p)
      # Insert the project so that target's children or root projects stay alphabetically sorted
      sibs = (p.nil? ? self.class.roots : p.children)
      to_be_inserted_before = sibs.detect {|c| c.name.to_s.downcase > name.to_s.downcase }
      if to_be_inserted_before
        move_to_left_of(to_be_inserted_before)
      elsif p.nil?
        if sibs.empty?
          # move_to_root adds the project in first (ie. left) position
          move_to_root
        else
          move_to_right_of(sibs.last) unless self == sibs.last
        end
      else
        # move_to_child_of adds the project in last (ie.right) position
        move_to_child_of(p)
      end
      true
    else
      # Can not move to the given target
      false
    end
  end

  # 获取当前部门及子部门下所有用户
  def all_members
    members = []

    members += self.users
    @children_departments = self.children
    @children_departments.each do |child|
      members += child.all_members
    end

    members
  end

  # 判断用户是否是负责人
  def is_manager(user)
    flag = false

    manager = self.manager
    sub_manager = self.sub_manager
    if user.id == manager.id
      flag = true
    end

    if !sub_manager.nil? && user.id == sub_manager.id
      flag = true
    end

    flag
  end

end
