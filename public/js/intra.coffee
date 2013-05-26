channel = window.channel

interval = (ms, func) -> setInterval func, ms
delay = (ms, func) -> setTimeout func, ms

window.users = {}
users = window.users

channel.onopen = (userid) ->
  console.log 'onopen ' + userid
  channel.send { test: 'hello' }
  users[userid] = {}

interval 1500, ->
  console.log 'trying to send'
  channel.send "hey there"

channel.onleave = (userid) ->
  delete users[userid]

channel.onmessage = (message, userid) ->  
  console.log "Message from #{userid}: #{JSON.stringify(message)}"

channel.onerror = (event) ->
  console.log "Data channel error:"
  console.log event

channel.onclose = (event) ->
  console.log "Data channel close!"
  console.log event

shorten = (url) ->
  return url
  if url.length < 45
    url
  else
    url.substr(0, 35) + '..' + url.substr((url.length-25), 25)

noraw = (url) ->
  if url.indexOf('github')>=0
    url.replace 'raw', 'blob'
  else
    url

listScripts = (data) ->
  found = false
  for script in data
    if script.url.indexOf('three.min.js') >= 0
      found = true
  if not found
    scripts.put { world: window.world, url: 'https://raw.github.com/mrdoob/three.js/master/build/three.min.js' }, ->
      loadScripts()
    return
  else  
    s = ''
    for script in data
      try       
        s += "<li class='scrname'><a style='display:inline;' href='javascript:removeScript(\"#{script.url}\");'>X</a><a style='display:inline' target='_blank' href='#{noraw(script.url)}'>#{shorten(script.url)}</a></li>"
      catch e
        console.log e
      
    s += '<li><a data-toggle="modal" data-target="#addScript">Add Script</a></li>'
    $('.scriptnav').html s

loadedScripts = {}

filename = (scripturl) ->
  lastSlash = scripturl.lastIndexOf('/')
  scripturl.substr lastSlash+1

notIn = (scriptList, toFind) ->
  for item in scriptList
    if filename(item.url) is filename(toFind.url)
      return false
  return true

sortAndLoad = (scripts) ->
  fullscripts = {}
  edges = []
  norequires = []
  for script in scripts
    fullscripts[filename(script.url)] = script
    reqtype = typeof(script.requires)
    reqtypestr = reqtype.toString()
    if not script.requires?
      norequires.push script
    else
      requires = script.requires.split ','         
      for req in requires
        mod = $.trim req      
        edges.push [ filename(script.url), mod ]

  sorted = window.toposort edges

  sorted = sorted.reverse()
  scriptList = []

  for name in sorted
    if fullscripts[name]?
      scriptList.push fullscripts[name]
    else
      console.log "missing required script #{name}"

  for item in norequires
    if notIn(scriptList, item)
      scriptList.push item

  loadNextScript scriptList, 0

statuscnt = 0
statuses = []
statusDelay = false

status = (text) ->
  console.log text
  statuses.push text
  if not statusDelay
    statusDelay = true
    delay 60, nextStatus

nextStatus = ->
  if statuses.length > 0
    $('.statusinfo').html statuses.shift() + ' &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; '

  if statuses.length > 0
    statusDelay = true
    delay 60, nextStatus 
  else
    statusDelay = false


loadNextScript = (list, i) ->
  if i > list.length-1
    status "#{i} scripts loaded."
    listScripts list
    return
  else
    script = list[i]

    if script? and not loadedScripts[script.url]?
      status 'LOADING SCRIPT WITH URL ' + script.url
      
      $.ajax {
        url: script.url
        crossDomain: true
        dataType: "script"
        success: ->            
          status 'Done loading script.'
          loadedScripts[script.url] = true
          delay 20, -> loadNextScript list, i+1
        error: (er) ->
          console.log 'ERROR loading script with url ' + script.url
          console.log er
          loadNextScript list, i+1
      }
    else
      status 'Already loaded ' + script.url + ', you must refresh to load again.'
      loadNextScript list, i+1

loadScripts = ->
  allScripts = []
  onScript = (script, cursor, trans) ->
    try
      allScripts.push script

    catch e1
      console.log "Error in onScript"
      console.log e1

  keyRange = scripts.makeKeyRange { lower: window.world, upper: window.world }

  scripts.iterate onScript, {
    index: 'world'
    order: 'ASC'
    keyRange: keyRange
    filterDuplicates: false
    writeAccess: false
    onEnd: -> sortAndLoad allScripts
    onError: (err) ->
      console.log 'there was an error iterating over scripts'
      console.log err
  }
    

scripts = new IDBStore {
  storeName: 'script'
  keyPath: 'id'
  autoIncrement: true
  dbVersion: 3
  onStoreReady: loadScripts
  indexes: [
    { name: 'world', keyPath: 'world', unique: false }
  ]
}

window.scripts = scripts

window.world = 'default'

listWorlds = (data) ->
  s = ''
  for world in data
    s += "<li class='scrname'><a style='display:inline;' href='javascript:removeWorld(\"#{world.name}\");'>X</a><a style='display:inline' target='_blank' href='javascript:loadWorld(\"#{world.name}\")'>#{world.name}</a></li>"
  s += '<li><a data-toggle="modal" data-target="#addWorld">Add World</a></li>'
  $('.worldnav').html s

loadWorlds = ->
  worlds.getAll (data) ->
    if data.length is 0
      worlds.put { name: 'default' }
      return loadWorlds()
    listWorlds data
    
worlds = new IDBStore {
  storeName: 'world'
  keyPath: 'name'
  onStoreReady: loadWorlds  
}

window.worlds = worlds

loadCurrentWorld = ->
  status "Loading world #{window.world}.."
  $('#currworld').html window.world
  loadScripts()

$ ->
  status 'Initializing..'
  $('.dropdown-toggle').dropdown()
     
  $('.dropdown input, .dropdown label').click (e) ->
    e.stopPropagation()
  
  window.toggleNav = ->
    $('.navbar').slideToggle()

  window.removeScript = (url) ->
    scripts.remove url, loadScripts

  window.addScript = ->
    newScript =
      url: $('#scripturl').val()
      world: window.world
      requires: $('#scriptrequires').val()

    scripts.put newScript, ->
      $('#addScript').modal('hide')
      loadScripts()
    
  window.removeWorld = (url) ->
    worlds.remove url, loadWorlds

  window.addWorld = ->
    console.log 'adding world'
    newWorld =
      name: $('#worldname').val()
    worlds.put newWorld, ->
      $('#addWorld').modal('hide')
      loadWorlds()
    return

  window.loadWorld = (name) ->
    status 'Loading world ' + name
    window.world = name
    loadCurrentWorld()

  delay 100, ->
    loadCurrentWorld()



