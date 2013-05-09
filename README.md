http failover - the poor man's load balancer / SOP killer
=========================================================

Well. Maybe not poor. More like..  Lazy.. and single-point-of-failure conscious. It uses HTTParty. Cause we have a disco ball.

The idea is that you instantiate a http failover client with the endpoints of your choise and then do gets and puts with only the URI from that point on.

It requires your requests to be idempotent as http failover will try resending your requests until it gets a success or dies.

It retires 500:s and timeouts.
It throws exceptions on 400:s
