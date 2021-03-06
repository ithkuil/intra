// Generated by CoffeeScript 1.6.2
(function() {
  var channel;

  window.DataChannel.prototype.openSignalingChannel = function(config) {
    var URL, channel, sender, socket;

    console.log('Hello   ...');
    URL = 'http://localhost:3000/';
    channel = config.channel || this.channel || 'default';
    sender = Math.round((Math.random() * 60535) + 5000);
    io.connect(URL).emit('new-channel', {
      channel: channel,
      sender: sender
    });
    socket = io.connect(URL + channel);
    socket.channel = channel;
    socket.on('connect', function() {
      return typeof config.callback === "function" ? config.callback(socket) : void 0;
    });
    socket.send = function(message) {
      return socket.emit('message', {
        sender: sender,
        data: message
      });
    };
    return socket.on('message', config.onmessage);
  };

  channel = new DataChannel('general');

  window.channel = channel;

}).call(this);
