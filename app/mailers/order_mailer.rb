class OrderMailer < ApplicationMailer
  default cc: -> { 'kristina.frey.frey@gmail.com' }

  def orders_report_email
    @orders = params[:orders]
    @items = params[:items]
    @automatically_fulfilled = params[:automatically_fulfilled]

    mail(to: 'bigabeano@yahoo.com', subject: 'Orders sent to Heftwerk')
  end
end
