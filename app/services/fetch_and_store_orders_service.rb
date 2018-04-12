require 'csv'
class FetchAndStoreOrdersService

  def save_international_orders_to_csv
    headers = ['OrderID','BusinessName','FullName','Address1','Address2','ZIP','City','State','CountryISOCode','Item','Quantity']

    file = File.new("tmp/international_orders_#{Date.today}.csv")

    CSV.open(file, 'w') do |csv|
      csv << headers
      pending_international_orders.each do |order|
        order['lineItems'].each do |item|
          csv << order_row(order, item)
        end
      end
    end

    upload_to_google_driv(file.path)
  end

  private

  def upload_to_google_driv(path)
    GoogleDriveService.new.upload_addresses(file_path)
  end

  def connection
    api_url_base = 'https://api.squarespace.com'

    Faraday.new(api_url_base)
  end

  def orders
    api_token = ENV['SQUARE_SPACE_TOKEN']

    response = connection.get do |req|
      req.url '1.0/commerce/orders'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Authorization'] = "Bearer #{api_token}"
    end

    JSON.parse(response.body)["result"]
  end

  def pending_international_orders
    orders.select do |o|
      o["shippingAddress"]["countryCode"] != 'US' &&
      o["fulfillmentStatus"] == "PENDING"
    end
  end

  def order_row(order, item)
    address = order['shippingAddress']
    business_name = ''
    [order['id'],business_name,"#{address['firstName']} #{address['lastName']}",address['address1'],address['address2'],address['postalCode'],address['city'],address['state'],address['countryCode'],item['productId'],item['quantity']].map do |value|
      value ? value.to_s[0..70] : ''
    end
  end

end
