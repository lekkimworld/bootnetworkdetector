#!/usr/bin/env node

var push = require("pushover-notifications");
var os = require("os");
var _ = require("underscore");
var Fiber = require('fibers');

// max wait (seconds)
var DO_NOTIFICATION = false;
var INITIAL_SLEEP = 0;
var MAX_WAIT = 30;

var sleep = function(ms) {
    var fiber = Fiber.current;
    setTimeout(function() {
        fiber.run();
    }, ms);
    Fiber.yield();
};

var addressesAquired = function(addresses) {
	// compose message
	var message = os.hostname() + " aquired IP address(es): ";
	var idx=0;
	_.each(addresses, function(address, key) {
		if (idx > 0) message += ", ";
		message += key;
		message += "=";
		message += address.address;
		idx++;
	});

	// send
	if (!DO_NOTIFICATION) {
		console.log(message);
		return;
	}

	var p = new push( {
	    user: process.env['PUSHOVER_USER'],
	    token: process.env['PUSHOVER_TOKEN'],
	});
	var msg = {
	    message: message, 
	    title: "Aquired IP address",
	    device: 'lekkim_iphone',
	    priority: 1
	};
	p.send(msg, function(err, result) {
	    if (err) {
	        throw err;
	    }
	    console.log(result);
	});
}

// wait for addresses
Fiber(function() {
	// aquire addresses
	var addresses = {};
	sleep(INITIAL_SLEEP * 1000);
	while (_.isEmpty(addresses) && process.uptime() < MAX_WAIT) {
		_.each(Object.keys(os.networkInterfaces()), function(key) {
			var ipv4 = _.find(os.networkInterfaces()[key], function(obj) {
				return obj.family == "IPv4" && !obj.internal;
			});
			if (!ipv4) return;
			addresses[key] = ipv4;
		});
		if (_.isEmpty(addresses)) {
			sleep(1000);
		} else {
			addressesAquired(addresses);
		}
	}
}).run();
