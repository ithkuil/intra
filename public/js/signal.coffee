
window.DataChannel.prototype.openSignalingChannel = (config) ->
   console.log 'Hello   ...'
   URL = 'http://localhost:3000/'
   channel = config.channel or this.channel or 'default'
   sender = Math.round (Math.random() * 60535) + 5000

   io.connect(URL).emit 'new-channel', { channel: channel, sender : sender }

   socket = io.connect URL + channel
   socket.channel = channel

   socket.on 'connect', -> config.callback? socket

   socket.send = (message) ->
      socket.emit 'message', { sender: sender, data  : message }

   socket.on 'message', config.onmessage

channel = new DataChannel 'general'

window.channel = channel
