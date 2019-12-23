require 'octokit'

##
# This module includes custom methods related to program errors in rails
module ErrorHandlers
  ##
  # This method rescues controller method calls from certain exceptions
  # and will handle them in a unique way
  # 
  # Params:
  # +clazz+::the class that this module was included in
  def self.included(clazz)
    clazz.class_eval do 
      # The rate limit as of 12/23/19 is 5000 request per hour with Basic Auth
      rescue_from Octokit::TooManyRequests, with: :rate_limit_error
    end
  end
  
private
  def rate_limit_error
    redirect_to '/RateLimitError.html'
  end
end
