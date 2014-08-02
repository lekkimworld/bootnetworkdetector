#!/usr/bin/env node

var push = require("pushover-notifications");
var os = require("os");
var _ = require("underscore");
var Fiber = require('fibers');
var argv = require("optimist")
	.usage("Send push notification via pushover whenever an IP address is obtained.\nUsage: $0")
	.demand("device")
	.describe("device", "The devide ID to use for the push notification")
	.default("initialwait", 0)
	.describe("initialwait", "The initial wait in seconds before starting to look for obtained IP address")
	.alias("iw", "initialwait")
	.default("maxwait", 30)
	.describe("maxwait", "The maximum number of seconds to wait for the system to obtain an IP address")
	.alias("mw", "maxwait")
	.default("notify", false)
	.describe("notify", "Should we actually send the push notification")
	.alias("n", "notify")
	.argv;

// max wait (seconds)
var DO_NOTIFICATION = argv.notify;
var INITIAL_SLEEP = argv.initialwait;
var MAX_WAIT = argv.maxwait;

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
	    device: argv.device,
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
