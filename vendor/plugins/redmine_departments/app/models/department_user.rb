class DepartmentUser < ActiveRecord::Base
  unloadable

  belongs_to :department
  belongs_to :user

  # after_destroy :remove_department_if_empty

  validates_presence_of :user


  private

  # def remove_department_if_empty
  #   if department.users.empty?
  #     department.destroy
  #   end
  # end
end