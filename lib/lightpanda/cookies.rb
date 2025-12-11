# frozen_string_literal: true

module Lightpanda
  class Cookies
    attr_reader :browser

    def initialize(browser)
      @browser = browser
    end

    def all
      result = browser.command("Network.getAllCookies")

      result["cookies"] || []
    end

    def get(name)
      all.find { |cookie| cookie["name"] == name }
    end

    def set(name:, value:, domain: nil, path: "/", secure: false, http_only: false, expires: nil)
      params = {
        name: name,
        value: value,
        path: path,
        secure: secure,
        httpOnly: http_only
      }

      params[:domain] = domain if domain
      params[:expires] = expires.to_i if expires

      browser.command("Network.setCookie", **params)
    end

    def remove(name:, domain: nil, path: "/")
      params = { name: name, path: path }
      params[:domain] = domain if domain

      browser.command("Network.deleteCookies", **params)
    end

    def clear
      browser.command("Network.clearBrowserCookies")
    end
  end
end
