class OrderMailer < ApplicationMailer
  default to: -> { 'kristina.frey.frey@gmail.com' }
  default cc: -> { 'kristina.frey.frey@gmail.com' }

  def orders_report_email
    @orders = params[:orders]
    @items = params[:items]
    @automatically_fulfilled = params[:automatically_fulfilled]

    mail(to: 'kristina.frey.frey@gmail.com', subject: 'Orders sent to Heftwerk')
  end
end
