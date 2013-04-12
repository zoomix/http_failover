require 'httparty'

class FailoverClient
  def initialize(base_uris)
    @base_uris = base_uris
    @request_counter = 0
  end

  def get(uri, options={})
    url = get_base_uri + uri
    HTTParty.get(url, options)
  end


  private

  def get_base_uri
    base_uri = @base_uris[@request_counter % @base_uris.size]
    @request_counter += 1
    base_uri
  end
end