# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.14' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))

# ... if these fail to include, you need the commonlib submodule from git

load "config.rb"
load "format.rb"
load "mapit.rb"
load "mask.rb"
load "url_mapper.rb"
load "util.rb"
load "validate.rb"
load "voting_area.rb"

# Patch Rails::GemDependency to cope with older versions of rubygems
# Restores override removed in https://github.com/rails/rails/commit/c20a4d18e36a13b5eea3155beba36bb582c0cc87
# without effecting method behaviour
# and adds fallback gem call removed in https://github.com/rails/rails/commit/4c3725723f15fab0a424cb1318b82b460714b72f
require File.join(File.dirname(__FILE__), '../lib/patches/old_rubygems_patch')


Rails::Initializer.run do |config|

  # Load intial mySociety config
  MySociety::Config.set_file(File.join(config.root_path, 'config', 'general.yml'), true)
  MySociety::Config.load_default

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.autoload_paths += %W( #{RAILS_ROOT}/app/sweepers )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  config.gem 'activerecord-diff', :version => '0.0.2'
  config.gem 'authlogic', :version => '2.1.6'
  config.gem 'bcrypt-ruby', :version => '2.1.4', :lib => 'bcrypt'
  config.gem "erubis", :version => '2.6.6'
  config.gem "fastercsv", :version => '1.5.3'
  config.gem 'foreigner', :version => '0.9.1'
  config.gem "friendly_id", :version => '3.1.7'
  config.gem 'paper_trail', :version => '1.5.1'
  config.gem "paperclip", :version => "~> 2.3"
  config.gem "rack", :version => '1.1.0'
  config.gem 'rspec', :lib => false, :version => '1.3.1'
  config.gem 'rspec-rails', :lib => false, :version => '1.3.3'
  config.gem 'session', :version => '3.1.0'
  config.gem 'text', :version => '0.2.0'
  config.gem 'will_paginate', :version => '2.3.15'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set the schema format to sql
  config.active_record.schema_format :sql

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]

  # Set the cache store
  cache_base_dir = MySociety::Config.get('CACHE_PARENT_DIRECTORY', RAILS_ROOT)
  config.cache_store = :file_store, File.join(cache_base_dir, 'cache')

  # override default fieldWithError divs in model-associated forms
  config.action_view.field_error_proc = Proc.new{ |html_tag, instance| html_tag }

end


# Use an asset host setting so that the admin interface can always get css, images, js.
if (MySociety::Config.get("DOMAIN", "") != "")
    ActionController::Base.asset_host = MySociety::Config.get("ASSET_HOST", 'localhost:3000')
end

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

# settings for exception notification
ExceptionNotification::Notifier.exception_recipients = MySociety::Config.get("BUGS_EMAIL", "")
ExceptionNotification::Notifier.sender_address = [MySociety::Config.get("BUGS_EMAIL", "")]
ExceptionNotification::Notifier.email_prefix = "[FixMyTransport] "