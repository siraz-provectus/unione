require 'unione/sender'
require "unione/version"

module Unione
  module Installer
    extend self

    def install
      ActionMailer::Base.add_delivery_method :unione, Unione::Sender
    end
  end
end

Unione::Installer.install
