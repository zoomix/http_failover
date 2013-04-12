require 'spec_helper'
require 'webmock/rspec'

describe FailoverClient do
  
  context 'Simple round robbin get' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'])
    end

    it 'Connects to the first server by default' do
      request = stub_request(:get, "http://apa/something")
      failover_client.get('/something')
      request.should have_been_requested
    end
    it 'Connects to the first and then the second' do
      request_a = stub_request(:get, 'http://apa/something')
      request_b = stub_request(:get, 'http://bepa:1337/something')

      2.times {failover_client.get('/something')}
      request_a.should have_been_requested
      request_b.should have_been_requested
    end
    it 'Connects to the first, then second, then first again' do
      request_a = stub_request(:get, 'http://apa/something')
      request_b = stub_request(:get, 'http://bepa:1337/something')
      
      3.times {failover_client.get('/something')}
      request_a.should have_been_requested.times(2)
      request_b.should have_been_requested
    end
  end

end