class FetchAndStoreOrdersService
  attr_accessor :fulfilled_orders, :fulfilled_items

  BOOK_SKUS = [
    'SQ7518949',
    'SQ5328310',
    'SQ4268897'
  ]

  def initialize
    @fulfilled_orders = []
    @fulfilled_items = []
  end

  def fetch_and_send_orders
    io = StringIO.new
    io.write("OrderID,Business Name,Full Name,Address 1,Address 2,ZIP,City,State,CountryISOCode,Item,Quantity,Email,Telephone\n")
    pending_international_orders.each do |order|
      if order['lineItems'].map { |li| li["sku"] }.uniq - BOOK_SKUS == []
        order['lineItems'].each do |item|
          io.write(order_row(order, item)) if BOOK_SKUS.include?(item["sku"])
          fulfilled_items << [item['productId'], item['productName']]
        end
        order_object = Order.create(order_id: order['id'], items: order['lineItems'], uploaded_at: Time.current)
        fulfilled_orders << order_object
      end
    end

    upload_to_google_drive(io)
    change_status_fulfilled(fulfilled_orders)
    OrderMailer.with(orders: fulfilled_orders.map(&:order_id), items: fulfilled_items, automatically_fulfilled: false).orders_report_email.deliver_now
  end

  def change_status_fulfilled(fo)
    fo.each do |o|
      # response = connection.post do |req|
      #   req.url "1.0/commerce/orders/#{o.order_id}/fulfillments"
      #   req.headers['Content-Type'] = 'application/json'
      #   req.headers['Authorization'] = "Bearer #{api_token}"
      #   req.body = {"shouldSendNotification":false,"shipments":[{ "shipDate": Time.current.to_s,"carrierName":"Heftwerk","service":"","trackingNumber": "","trackingUrl": ''}]}.to_json
      # end
      # o.update(fulfilled_at: Time.current)
    end
    fo.count
  end

  private

  def upload_to_google_drive(io)
    GoogleDriveService.new.upload_addresses(io)
  end

  def connection
    api_url_base = 'https://api.squarespace.com'

    Faraday.new(api_url_base)
  end

  def orders
    api_token = ENV['SQUARE_SPACE_TOKEN']

    response = connection.get do |req|
      req.url '1.0/commerce/orders'
      req.params['fulfillmentStatus'] = 'PENDING'
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
    [order['id'],business_name,"#{address['firstName']} #{address['lastName']}",address['address1'],address['address2'],address['postalCode'],address['city'],address['state'],address['countryCode'],item['sku'],item['quantity'],order['customerEmail'],address['phone']].map do |value|
      value ? value.to_s[0..70].gsub(',', '') : ''
    end.join(',') + "\n"
  end

end

# connection.post do |req|
#  req.url "/commerce/orders/5abbb67c03ce649f5bbd141d/fulfillments"
#  req.headers['Content-Type'] = 'application/json'
#  req.headers['Authorization'] = "Bearer #{api_token}"
#  req.body = {"shouldSendNotification":false,"shipments":[{ "shipDate": Time.current.to_s,"carrierName":"Heftwerk","service":"overnight","trackingNumber": "","trackingUrl": ''}]}.to_json
# end
#
# response = connection.get do |req|
#   req.url "1.0/commerce/orders/5abbb67c03ce649f5bbd141d"
#   req.headers['Content-Type'] = 'application/json'
#   req.headers['Authorization'] = "Bearer #{api_token}"
# end
