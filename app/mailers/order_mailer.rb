class OrderMailer < ApplicationMailer
  default cc: -> { ['kristina.frey.frey@gmail.com', 'dan.r.eils@gmail.com'] }

  def orders_report_email
    @orders = Orders.where(order_id: params[:orders])
    @items = params[:items]

    mail(to: 'bigabeano@yahoo.com', subject: 'Orders sent to Heftwerk')
  end
end
