class IncomingTicketHandler < ActionMailer::Base

  def receive(email)
    ticket = Ticket.new
    ticket.from_email = email.from[0]
    ticket.initial_report = email.body
    if email.has_attachments?
      email.attachments.each do |attachment|
        collateral = TicketCollateral.new(
                       :name         => attachment.original_filename,
                       :body         => attachment.read)
        ticket.ticket_collaterals << collateral
      end
    end
    ticket.save
  end
end
