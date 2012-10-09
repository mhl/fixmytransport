require 'uri'

class OptionsController < ApplicationController

  # This controller is for dealing with requests with the OPTIONS
  # verb, as used for preflighted checks for CORS (Cross-Origin
  # Resource Sharing):
  #
  #   https://developer.mozilla.org/en-US/docs/HTTP_access_control
  #   http://www.w3.org/TR/cors/
  #
  # These mostly seem to come from either buggy clients, or from
  # Google Translate or the Google cache.  I'm unsure about whether
  # this is actually worth dealing with in Rails - the AJAX calls
  # still seem to work via Google Translate even with the OPTIONS
  # requests returning a 500 error, and if we just wanted to suppress
  # the error, this could be done by refusing all requests with the
  # OPTIONS verb in the Apache config.

  def check
    # Get the Origin header, and see if it's one that we allow:
    origin = request.env['HTTP_ORIGIN']
    unless origin
      return forbid "No Origin header found"
    end
    uri = URI.parse origin.strip
    host = uri.host
    unless host
      forbid "No host found in the Origin: header"
    end
    if origin_allowed? uri.host, uri.port
      headers['Access-Control-Allow-Origin'] = origin
      headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
      headers['Access-Control-Max-Age'] = '86400'
      headers['Access-Control-Allow-Headers'] = 'X-Requested-With, X-CSRF-Token'
      head :ok
    else
      return forbid "Cross-origin requests are not allowed from that origin"
    end
  end

  private

  def origin_allowed?( origin_host, origin_port )
    fmt_regex = /(^|\.)fixmytransport.com/
    if request.host =~ fmt_regex
      # If we're running on the main site, allow any origin in the
      # domain fixmytransport.com:
      return origin_host =~ fmt_regex
    elsif ['webcache.googleusercontent.com', 'translate.googleusercontent.com'].include? origin_host
      # Also allow requests when browsing the site via Google
      # translate or the Google web cache:
      return true
    else
      # Otherwise, the host and port must match:
      return (origin_host == request.host) && (origin_port == request.port)
    end

  end

  def forbid( message )
    render( :status => :forbidden, :text => message )
    nil
  end

end
