class FetchAndStoreOrdersService
  attr_accessor :fulfilled_orders,
                :fulfilled_items,
                :line_items,
                :posters_not_sent,
                :orders_already_uploaded

  BOOK_SKUS = [
    'CRC',
    'EBE',
    'PBHB',
    'DCB',
    'CSH',
    'XTS',
    'CRBP'
  ]

  POSTER_SKU = [
   'DCBP'
  ]

  def initialize
    @fulfilled_orders = []
    @fulfilled_items = []
    @line_items = []
    @posters_not_sent = []
    @orders_already_uploaded = []
  end

  def fetch_and_send_orders
    pending_international_orders.each do |order|
      if order['lineItems'].map { |li| li["sku"] }.uniq - (BOOK_SKUS + POSTER_SKU) == []
        order_record = Order.find_or_initialize_by(order_number: order['orderNumber'])

        if order_record.uploaded_at.present?
          orders_already_uploaded << order_record
          next
        else
          order_record.update(order_id: order['id'], items: order['lineItems'])

          order['lineItems'].map do |item|
            if BOOK_SKUS.include?(item['sku'])
              line_items << order_row(order, item)
              fulfilled_items << [item['productId'], item['productName']]
            else
              posters_not_sent << [order_record.order_number, item['productName']]
              order_record.update(contains_poster: true)
            end
          end
          order_record.update(uploaded_at: Time.current)
          fulfilled_orders << order_record
        end
      end
    end

    GoogleDriveService.new.append_orders(line_items)
    change_status_fulfilled(fulfilled_orders)
    send_email
  end

  def change_status_fulfilled(fo)
    api_token = ENV['SQUARE_SPACE_TOKEN']

    conn = Faraday.new(url: 'https://api.squarespace.com/1.0/commerce/orders') do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end

    fo.each do |o|
      unless o.contains_poster?
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
    [order['orderNumber'],business_name,"#{address['firstName']} #{address['lastName']}",address['address1'],address['address2'],address['postalCode'],address['city'],address['state'],address['countryCode'],item['sku'],item['quantity'],order['customerEmail'],address['phone']].map do |value|
      value ? value.to_s[0...70].gsub(',', ' ') : ''
    end
  end

  def send_email
    OrderMailer.with(orders: fulfilled_orders.map(&:order_id),
                     items: fulfilled_items,
                     posters: posters_not_sent,
                     orders_already_uploaded: orders_already_uploaded.map(&:order_id))
                     .orders_report_email.deliver_now
  end

end
