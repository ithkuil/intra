
express = require 'express'

process.env.NODE_ENV = 'production'

app = express()

server = require('http').createServer app

app.use express.compress()
app.use express.static('public')
app.use express.bodyParser()
app.use express.methodOverride()

io = require('socket.io').listen server

server.listen 3000

io.sockets.on 'connection', (socket) ->
  if not io.connected? then io.connected = true

  socket.on 'new-channel', (data) ->
    onNewNamespace data.channel, data.sender

onNewNamespace = (channel, sender) ->
  io.of('/' + channel).on 'connection', (socket) ->
    if io.isConnected
      io.isConnected = false
      socket.emit 'connect', true

    socket.on 'message', (data) ->
      if data.sender is sender
        socket.broadcast.emit 'message', data.data

process.on 'uncaughtException', (err) ->
  e.log.error 'Uncaught exception in service:'
  e.log.error err
  e.log.error err.stack


