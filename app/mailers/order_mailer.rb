class OrderMailer < ApplicationMailer
  default cc: -> { ['kristina.frey.frey@gmail.com', 'dan.r.eils@gmail.com'] }

  def orders_report_email
    @orders = Order.where(order_id: params[:orders])
    @items = params[:items]
    @posters = params[:posters]

    mail(to: 'bigabeano@yahoo.com', subject: 'Orders sent to Heftwerk')
  end
end
