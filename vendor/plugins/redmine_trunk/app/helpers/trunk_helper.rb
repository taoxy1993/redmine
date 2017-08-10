module TrunkHelper

  # change_status_link method
  def change_status_link(trunk)
    if trunk.status == Trunk::STATUS_NORMAL
      link_to l(:button_freeze),
              { :controller => 'trunk', :action => 'freeze', :id => @project, :trunk_id => trunk },
              :confirm => l(:text_are_you_sure),
              :method => :post,
              :class => 'icon icon-lock'
    else trunk.status == Trunk::STATUS_FROZEN
      link_to l(:button_unfreeze),
              { :controller => 'trunk', :action => 'unfreeze', :id => @project, :trunk_id => trunk },
              :confirm => l(:text_are_you_sure),
              :method => :post,
              :class => 'icon icon-unlock'
    end
  end

  # format status
  def format_status(trunk)
    if trunk.status == Trunk::STATUS_NORMAL
      l(:trunk_status_normal)
    else trunk.status == Trunk::STATUS_FROZEN
      l(:trunk_status_frozen)
    end
  end
end
