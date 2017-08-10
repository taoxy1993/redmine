class Trunk < ActiveRecord::Base
  unloadable

  # Trunk statuses
  STATUS_NORMAL = 'normal'
  STATUS_FROZEN = 'frozen'

  # Is frozen ?
  def frozen?
    self.status == STATUS_FROZEN
  end

  # Freeze the svn path, update status
  def freeze
    update_attribute :status, STATUS_FROZEN
  end

  # Unfreeze the svn path, update status
  def unfreeze
    update_attribute :status, STATUS_NORMAL
  end

end
