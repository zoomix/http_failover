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

  context 'Client erorrs' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'])
    end

    it 'Throws an exception for 403.' do
      request_a = stub_request(:get, 'http://apa/something').to_return(status: 403, body: 'forbidden')
      expect {failover_client.get('/something')}.to raise_error(HttpClienError)
    end

    it 'Throws an exception for 404 with no message' do
      request_a = stub_request(:get, 'http://apa/something').to_return(status: 404)
      expect {failover_client.get('/something')}.to raise_error(HttpClienError)
    end

    it 'Copies extra data in exceptions' do
      begin
        request_a = stub_request(:get, 'http://apa/something').to_return(status: 403, body: 'forbidden', :headers => { 'Content-Length' => 9 })
        failover_client.get('/something')
      rescue => e
        e.code.should == 403
        e.status.should == 403
        e.body.should == 'forbidden'
        e.headers.should == {"content-length"=>["9"]}
      end
    end
  end

  context 'Redirects' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'])
    end

    it 'follows redirects' do
      request_a = stub_request(:get, 'http://apa/something').to_return(:status => 301, :headers => { 'Location' => 'http://apa/something_2' })
      request_b = stub_request(:get, 'http://apa/something_2')
      failover_client.get('/something')
      request_a.should have_been_requested
      request_b.should have_been_requested
    end
  end


end