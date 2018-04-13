desc "This task is called by the Heroku scheduler add-on"

task :upload_international_orders => :environment do
  puts "Pulling and uploading international orders..."
  if Time.current.to_date.monday? || Time.current.to_date.thursday?
    count = FetchAndStoreOrdersService.new.fetch_and_send_orders
    puts "Done fetching and sending #{count} orders #{Time.current}."
  else
    puts "#{Date.today} is not monday or thursday so nothing was uploaded"
  end
end
