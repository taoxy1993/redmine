# config/initializers/appliaction_config.rb

CONFIG_PATH="#{RAILS_ROOT}/config/application.yml"
APP_CONFIG = YAML.load_file(CONFIG_PATH)[Rails.env]