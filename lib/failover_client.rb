require 'httparty'

class FailoverClient
  def initialize(base_uris, retry_timeouts = [1, 5, 5])
    @base_uris = base_uris
    @request_counter = 0
    @retry_timeouts = retry_timeouts
    @retry = 0
  end

  def get(uri, options={})
    url = get_base_uri + uri
    response = HTTParty.get(url, options)
    raise HttpClientError.new(response.code, response.body, response.headers) if (400..499).cover? response.code
    raise HttpServerError.new(response.code, response.body, response.headers) if (500..599).cover? response.code
    @retry = 0
    response
  rescue Timeout::Error, HttpServerError => e
    response = retryer(e, uri)
  end

  private

  def retryer(error, uri)
    if @retry < @retry_timeouts.count 
      sleep @retry_timeouts[@retry]
      @retry += 1
      get(uri)
    else
      raise error
    end
  end

  def get_base_uri
    base_uri = @base_uris[@request_counter % @base_uris.size]
    @request_counter += 1
    base_uri
  end
end

class HttpClientError < StandardError
  attr :code, :status, :body, :headers
  def initialize(code, body, headers)
    super("code: #{code}, body: #{body}")
    @code = code
    @status = code
    @body = body
    @headers = headers
  end
end
class HttpServerError < HttpClientError; end;