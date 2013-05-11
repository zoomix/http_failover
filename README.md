# http failover

## What is it
.. the poor man's load balancer / SPoF killer

Well. Maybe not poor. More like..  Lazy.. and single-point-of-failure conscious. It uses HTTParty. Cause we have a disco ball.

The idea is that you instantiate a http failover client with the endpoints of your choise and then do regular gets and puts and so on with only the URI from that point on. If anything goes wrong with the requests, http failover will automatically handle that and connect to the other endpoint. 

It requires your requests to be idempotent as http failover will try resending your requests until it gets a success or dies. It isn't inherently thread safe, so you need to handle that yourself - the object is lightweight, so just go ahead and create a new one for each thread. Unless that's what's causing your problems in the first place. Damn threads. Well.. I'm not sure I want to go solve that problem now anyway. Sorry. 

## How does it work

    failover_client = FailoverClient.new(['http://1.google.com', 'http://2.google.com'])
    failover_client.get('/my_goodies?params=1') # => HTTParty response. (with .code, .message, .headers, etc)

That'll give you the default 3 timeouts with default back-offs of 1, 5, 5. That means that your request can fail 3 times, but if it fails a 4:th time the errors gets re-raised. Back-offs mean that the first retry is commenced after 1 second, the second after 5 and a third after another 5. This is so you'll be nice to the servers if they're too busy. Change number of retries and back-off values by sending a second parameter to FailoverClient

    failover_client = FailoverClient.new(['http://1.google.com', 'http://2.google.com'], [0.1, 5, 10, 15])



### Working:
 - Round robin get-request
 - Handles timeouts
 - Retries on 5xx

### Future:
 - Retires on network errors
 - post/delete/put requests
 - Dynamic end_point update


## Disclaimer.
I should be sincerily disappointed if this project exceeds 100 lines of code. 