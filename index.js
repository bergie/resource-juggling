require('coffee-script');
var juggler = require('./lib/resource-juggling.coffee');
exports.contentNegotiator = juggler.contentNegotiator;
exports.getResource = juggler.getResource;
