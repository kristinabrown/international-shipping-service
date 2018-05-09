class FetchAndStoreOrdersService
  attr_accessor :fulfilled_orders, :fulfilled_items

  BOOK_SKUS = [
    'CRC',
    'EBE',
    'PBHB',
    'DCB'
  ]

  POSTER_SKU = [
   'DCBP'
  ]

  def initialize
    @fulfilled_orders = []
    @fulfilled_items = []
  end

  def fetch_and_send_orders
    line_items = []
    posters_not_sent = []
    pending_international_orders.each do |order|
      if order['lineItems'].map { |li| li["sku"] }.uniq - (BOOK_SKUS + POSTER_SKU) == []
        order['lineItems'].map do |item|
          if BOOK_SKUS.include?(item["sku"])
            line_items << order_row(order, item)
            fulfilled_items << [item['productId'], item['productName']]
          else
            posters_not_sent << [order['id'], item['productName']]
          end
        end
        order_object = Order.create(order_id: order['id'], items: order['lineItems'], uploaded_at: Time.current)
        fulfilled_orders << order_object
      end
    end

    GoogleDriveService.new.append_orders(line_items)
    change_status_fulfilled(fulfilled_orders)
    OrderMailer.with(orders: fulfilled_orders.map(&:order_id), items: fulfilled_items, posters: posters_not_sent, automatically_fulfilled: true).orders_report_email.deliver_now
  end

  def change_status_fulfilled(fo)
    api_token = ENV['SQUARE_SPACE_TOKEN']

    conn = Faraday.new(url: 'https://api.squarespace.com/1.0/commerce/orders') do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end

    fo.each do |o|
      shipment = {
        "carrierName": 'Heftwerk',
        "service": "standard",
        "shipDate": "#{Time.now.utc.iso8601}",
        "trackingNumber": '123',
        "trackingUrl": nil
      }

      response = conn.post do |req|
        req.headers['Content-Type'] = 'application/json'
        req.headers['Authorization'] = "Bearer #{api_token}"
        req.url "#{o.order_id}/fulfillments"
        req.body = req.body = {"shipments":[shipment],"shouldSendNotification": false}.to_json
      end
      o.update(fulfilled_at: Time.current) if response.success?
    end
    fo.count
  end

  private

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
    [order['id'].to_s[0...20],business_name,"#{address['firstName']} #{address['lastName']}",address['address1'],address['address2'],address['postalCode'],address['city'],address['state'],address['countryCode'],item['sku'],item['quantity'],order['customerEmail'],address['phone']].map do |value|
      value ? value.to_s[0...70].gsub(',', '') : ''
    end
  end

end
