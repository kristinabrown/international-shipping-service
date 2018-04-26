desc "This task is called by the Heroku scheduler add-on"

task :upload_international_orders => :environment do
  puts "Pulling and uploading international orders..."
  count = FetchAndStoreOrdersService.new.fetch_and_send_orders
  puts "Done fetching and sending #{count} orders #{Time.current}."
end
