require 'httparty'

class FailoverClient
  def initialize(base_uris)
    @base_uris = base_uris
    @request_counter = 0
  end

  def get(uri, options={})
    url = get_base_uri + uri
    response = HTTParty.get(url, options)
    raise HttpClienError.new(response.code, response.body, response.headers) if (400..499).cover? response.code
    response
  end

  private

  def get_base_uri
    base_uri = @base_uris[@request_counter % @base_uris.size]
    @request_counter += 1
    base_uri
  end
end

class HttpClienError < StandardError
  attr :code, :status, :body, :headers
  def initialize(code, body, headers)
    super("code: #{code}, body: #{body}")
    @code = code
    @status = code
    @body = body
    @headers = headers
  end
end
