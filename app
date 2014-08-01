#!/usr/bin/env node

var push = require("pushover-notifications");
var os = require("os");
var _ = require("underscore");
var Fiber = require('fibers');

// max wait (seconds)
var max_wait = 30;

var sleep = function(ms) {
    var fiber = Fiber.current;
    setTimeout(function() {
        fiber.run();
    }, ms);
    Fiber.yield();
};

var addressesAquired = function(addresses) {
	var p = new push( {
	    user: process.env['PUSHOVER_USER'],
	    token: process.env['PUSHOVER_TOKEN'],
	});
	var msg = {
	    message: os.hostname() + " aquired an IP address of " + addresses.en0.address, 
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
	while (_.isEmpty(addresses) && process.uptime() < max_wait) {
		_.forEach(Object.keys(os.networkInterfaces()), function(key) {
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
