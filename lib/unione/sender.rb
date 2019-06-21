require 'unione/client'
module Unione
  class Sender

    attr_reader :settings

    def initialize(args)
      @settings = { api_key: nil, username: nil }

      @logger = Rails.logger
      @logger.info "UNIONE:INIT"

      args.each do |arg_name, arg_value|
        @settings[arg_name.to_sym] = arg_value
      end

      @client = Unione::Client.new(@settings[:api_key], @settings[:username])
    end

    def deliver!(mail)
      recipients = []
      inline_attachments = []
      mail_to    = [*mail.to]

      @logger.info "--- UNIONE: deliver! method ---"
      @logger.info "--- UNIONE: mail_to = #{mail_to.inspect} ---"

      return if mail_to.blank?

      mail_to.each do |email_address|
        recipients << {email: email_address}
      end

      mail_body = if mail.attachments.present?
        mail.html_part.body.raw_source
      else
        mail.body.raw_source
      end

      mail.attachments.each do |attachment|
        @logger.info "--- UNIONE:MAIL attachments #{attachment.inspect}"
        if attachment.filename.match('inline').present?
          inline_attachments << { type: attachment[:type].to_s, name: attachment[:name].to_s, content: Base64.encode64(File.read(attachment[:fileurl].to_s)) }
        end
      end

      send_params = {
        message: {
          subject: mail.subject,
          from_email: mail.from.first,
          from_name: sender_name(mail.From.unparsed_value),
          recipients: recipients,
          body: { html: mail_body },
          inline_attachments: inline_attachments
        }
      }

      @logger.info "--- UNIONE: send emails ---"

      @settings[:history_status_model].create(status: 'send', comment: "Отправка письма #{mail.subject}") if @settings[:history_status_model].present?

      result = @client.send_emails(send_params)

      if @settings[:client_model].present?
        if "#{@settings[:client_model]}" == 'Customer'
          customer = ::Customer.find_by(email: recipients.first[:email])

          user_id = nil
          customer_id = customer.present? ? customer.id : nil
        elsif "#{@settings[:client_model]}" == 'User'
          user = ::User.find_by(email_address: recipients.first[:email])
          user ||= ::User.find_by(email: recipients.first[:email])

          user_id = user.present? ? user.id : nil
          customer_id = nil
        elsif @settings[:client_model].present?
          user = @settings[:client_model].find_by(email: recipients.first[:email])

          user_id = user.present? ? user.id : nil
          customer_id = nil
        end
      end

      body = result[:body]

      if @settings[:unione_email_model].present?
        if result[:code] == "200"
          @settings[:unione_email_model].create(job_id: body["job_id"],
                                                title: mail.subject,
                                                customer_id: customer_id,
                                                user_id: user_id,
                                                status: body["status"],
                                                email: body["emails"].first,
                                                site_id: @settings[:site_id])
        else
          @settings[:unione_email_model].create(title: mail.subject,
                                                customer_id: customer_id,
                                                user_id: user_id,
                                                status: body["status"],
                                                email: body['failed_emails'].present? ? body['failed_emails'].keys.first : recipients.first[:email],
                                                substatus: body['failed_emails'].present? ? body['failed_emails'].values.first : '',
                                                site_id: @settings[:site_id])

        end
      end

      @logger.info "--- UNIONE: response = #{result.inspect} ---"
      result
    end

    def sender_name(mail_from)
      # ActionMailer::Base default sender form `Bill Gates <bill@microsoft.com>`
      
      default_mail_form_regexp = / <[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+>/ 
      if mail_from.match default_mail_form_regexp
        mail_from.sub default_mail_form_regexp, ''
      else
        @settings[:sender_name] || mail_from.split('@').first
      end
    end
  end
end
