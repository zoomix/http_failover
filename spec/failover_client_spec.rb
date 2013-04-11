require 'spec_helper'
require 'webmock/rspec'

describe FailoverClient do
  
  context 'Simple round robbin get' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'])
    end

    it 'Connects to the first server by default' do
      failover_client.get('/something')
      stub_request(:get, 'http://apa/something').should have_been_requested
    end
    it 'Connects to the first and then the second' do
      2.times {failover_client.get('/something')}
      failover_client.get('/something')
      stub_request(:get, 'http://apa/something').should have_been_requested
      stub_request(:get, 'http://bepa:1337/something').should have_been_requested
    end
    it 'Connects to the first, then second, then first again' do
      3.times { failover_client.get('/something') }
      stub_request(:get, 'http://apa/something').should have_been_requested
      stub_request(:get, 'http://bepa:1337/something').should have_been_requested
      stub_request(:get, 'http://apa/something').should have_been_requested
    end
  end

end