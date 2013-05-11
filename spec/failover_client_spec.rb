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
      expect {failover_client.get('/something')}.to raise_error(HttpClientError)
    end

    it 'Throws an exception for 404 with no message' do
      request_a = stub_request(:get, 'http://apa/something').to_return(status: 404)
      expect {failover_client.get('/something')}.to raise_error(HttpClientError)
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

  context 'Timeouts' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'], [0.1, 0.1, 0.1])
    end

    it 'tries the other server if the first times out' do
      request_a = stub_request(:get, 'http://apa/something').to_timeout
      request_b = stub_request(:get, 'http://bepa:1337/something')
      failover_client.get('/something')
      request_a.should have_been_requested
      request_b.should have_been_requested
    end

    it 'keep retrying until it runs out of retries. Then throws the error' do
      stub_request(:get, 'http://bepa:1337/something').to_timeout
      stub_request(:get, 'http://apa/something').to_timeout
      expect { failover_client.get('/something') }.to raise_error(Timeout::Error)
    end

    it 'gets the last' do
      new_failover_client = FailoverClient.new(['http://apa', 'http://bepa', 'http://cepa', 'http://depa'], [0.1, 0.1, 0.1])
      r_d = stub_request(:get, 'http://depa/something').to_return({status: 200, body: 'Finally. A response.'})
      r_c = stub_request(:get, 'http://cepa/something').to_timeout
      r_b = stub_request(:get, 'http://bepa/something').to_timeout
      r_a = stub_request(:get, 'http://apa/something').to_timeout
      response = new_failover_client.get('/something')
      response.code.should == 200
      response.body.should == 'Finally. A response.'
    end
  end

  context 'Server errors' do
    let :failover_client do
      FailoverClient.new(['http://apa', 'http://bepa:1337'], [0.1, 0.1, 0.1])
    end

    it 'tries the other server if the first times out' do
      request_a = stub_request(:get, 'http://apa/something').to_return({status: 501})
      request_b = stub_request(:get, 'http://bepa:1337/something')
      failover_client.get('/something')
      request_a.should have_been_requested
      request_b.should have_been_requested
    end

    it 'keep retrying until it runs out of retries. Then throws the error' do
      stub_request(:get, 'http://bepa:1337/something').to_return({status: 503})
      stub_request(:get, 'http://apa/something').to_return({status: 503})
      expect { failover_client.get('/something') }.to raise_error(HttpServerError)
    end

    it 'gets the last' do
      new_failover_client = FailoverClient.new(['http://apa', 'http://bepa', 'http://cepa', 'http://depa'], [0.1, 0.1, 0.1])
      r_d = stub_request(:get, 'http://depa/something').to_return({status: 200, body: 'Finally. A response.'})
      r_c = stub_request(:get, 'http://cepa/something').to_return({status: 500})
      r_b = stub_request(:get, 'http://bepa/something').to_return({status: 503})
      r_a = stub_request(:get, 'http://apa/something').to_return({status: 504})
      response = new_failover_client.get('/something')
      response.code.should == 200
      response.body.should == 'Finally. A response.'
    end
  end

end