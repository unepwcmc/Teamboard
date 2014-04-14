require "net/http"

class MainController < ApplicationController

  def index
  end

  def nagios_api
    uri = URI Rails.application.config.nagios_api_url
    req = Net::HTTP::Get.new uri

    if Rails.application.config.nagios_api_needs_auth
      req.basic_auth(
        Rails.application.config.nagios_api_username,
        Rails.application.config.nagios_api_password
      )
    end

    res = Net::HTTP.start(uri.hostname, uri.port) { |http|
      http.request req
    }
    render json: res.body
  end
end
