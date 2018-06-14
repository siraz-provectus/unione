require 'net/http'
require 'json'

module Unione
  class Client
  private
    attr_reader :api_key, :username

    def initialize(api_key, username)
      @api_key  = api_key
      @username = username
    end

    def translate_params(params)
      params.inject({}) do |iparams, (k, v)|
        if k == :field_names
          v.each_with_index do |name, index|
            iparams["field_names[#{index}]"] = name
          end
        elsif k == :data
          v.each_with_index do |row, index|
            row.each_with_index do |data, data_index|
              iparams["data[#{index}][#{data_index}]"] = data
            end if row
          end
        else
          case v
          when String
            iparams[k.to_s] = v
          when Array
            iparams[k.to_s] = v.map(&:to_s).join(',')
          when Hash
            v.each do |key, value|
              if value.is_a? Hash
                value.each do |v_key, v_value|
                  iparams["#{k}[#{key}][#{v_key}]"] = v_value.to_s
                end
              else
                iparams["#{k}[#{key}]"] = value.to_s
              end
            end
          else
            iparams[k.to_s] = v.to_s
          end
        end
        iparams
      end
    end


    def send_emails(params)
      params = translate_params(params).delete_if { |_, v| !v.present? }
      params.merge!({ 'api_key' => api_key, 'username'=> username, 'format' => 'json' })
      response = Net::HTTP.post_form(URI("https://one.unisender.com/ru/transactional/api/v1/email/send"), params)

      { body: JSON.parse(response.body), code: response.code }
    end
  end
end