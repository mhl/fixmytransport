namespace :guides do

  desc 'Add the static guides to common problems'
  task :add_static_guides => :environment do
    Guide.delete_all
    Guide.create! :partial_name => "accessibility", :title => "Making your public transport accessible"
    Guide.create! :partial_name => "bus_stop_fixed", :title => "Getting your bus stop fixed"
    Guide.create! :partial_name => "rude_staff", :title => "Reporting rude transport staff"
    Guide.create! :partial_name => "discontinued_bus", :title => "Getting bus routes reinstated"
    Guide.create! :partial_name => "delayed_bus", :title => "Getting your bus to run on time"
    Guide.create! :partial_name => "overcrowding", :title => "Overcrowded trains, and what to do about them"
  end

end
