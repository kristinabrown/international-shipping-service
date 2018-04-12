require 'csv'
class FetchAndStoreOrdersService

  def save_international_orders_to_csv
    io = StringIO.new
    pending_international_orders.each do |order|
      order['lineItems'].each do |item|
        io.write(order_row(order, item))
      end
    end

    upload_to_google_drive(io)
  end

  private

  def upload_to_google_drive(path)
    GoogleDriveService.new.upload_addresses(path)
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
