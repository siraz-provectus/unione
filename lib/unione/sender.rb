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
          from_name: @settings[:sender_name] || mail.from.split('@').first,
          recipients: recipients,
          body: { html: mail.html_part.body.raw_source },
          inline_attachments: inline_attachments
        }
      }

      @logger.info "--- UNIONE: send emails ---"

      result = @client.send_emails(send_params)

      if result[:code] == "200" && @settings[:unione_email_model]
        body = result[:body]
        @settings[:unione_email_model].create(job_id: body["job_id"], title: mail.subject)
      end

      @logger.info "--- UNIONE: response = #{result.inspect} ---"
      result
    end
  end
end
