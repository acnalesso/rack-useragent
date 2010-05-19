require 'rubygems'
require 'user_agent'
require 'erb'
require 'ostruct'

module Rack::UserAgent
  class Filter
    def initialize(app, config = [], options = {})
      @app                = app
      @browsers           = config
      @template           = options[:template]
      @force_with_cookie  = options[:force_with_cookie]
    end
    
    def call(env)
      browser = UserAgent.parse(env["HTTP_USER_AGENT"]) if env["HTTP_USER_AGENT"]
      if !detection_disabled_by_cookie?(env['rack.cookies']) && unsupported?(browser)
        content = page(env['rack.locale'], browser)
        [400, {"Content-Type" => "text/html", "Content-Length" => content.length.to_s}, content]
      else
        @app.call(env)
      end
    end
    
    private
    
    def unsupported?(browser)
      browser && @browsers.any? { |hash| browser < OpenStruct.new(hash) }
    end

    def detection_disabled_by_cookie?(cookies)
      @force_with_cookie && cookies.keys.include?(@force_with_cookie)
    end
    
    def page(locale, browser)
      return "Sorry, your browser is not supported. Please upgrade" unless template = template_file(locale)
      @browser = browser # for the template
      ERB.new(File.read(template)).result(binding)
    end
    
    def template_file(locale)
      candidates = [ @template ]
      
      if defined?(RAILS_ROOT)
        candidates += [ File.join(RAILS_ROOT, "public", "upgrade.#{locale}.html"),
          File.join(RAILS_ROOT, "public", "upgrade.html") ] 
        end
        
        candidates.compact.detect{ |template| File.exists?(template) }
      end
    end
  end
