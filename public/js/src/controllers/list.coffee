app = angular.module('CoffeeModule')
db = 'supermarket'

app.controller "ListCtrl", ($scope) ->
  currentListName = 'supermarket'

  $scope.chooseDb = chooseDb = (name) ->
    $scope.currentListName = currentListName = name
    updateHash(name)

  updateHash = (name) ->
    window.location.hash = "#/#{currentListName}"

  debounce = null

  $scope.$watch 'currentListName', (newVal, oldVal) ->
    clearTimeout debounce
    debounce = setTimeout ->
      chooseDb newVal
    , 500

  checkHash = ->
    targetName = window.location.hash.split('#/')[1]
    if targetName is undefined
      targetName = 'supermarket'
    chooseDb(targetName)

  checkHash()

  $scope.currentListName = currentListName
  items = {}
  $scope.items = items

  globalishReplicationHandle =
    out:
      cancel: ->
    in:
      cancel: ->

  setReplication = (relevant, currentListName) ->
    globalishReplicationHandle.out.cancel()
    globalishReplicationHandle.in.cancel()

    globalishReplicationHandle.out = PouchDB.replicate(currentListName, "http://yankee.davidbanham.com:5984/#{currentListName}", {
      live: true
      retry: true
      batch_size: 1000
    })
    .on 'paused', ->
      $scope.loading = false
    .on 'active', ->
      $scope.loading = true
    .on 'denied', (info) ->
      alert("Permission denied! #{info}")
    .on 'complete', (info) ->
      $scope.loading = false
    .on 'error', (err) ->
      alert("error! #{err.message}")

    globalishReplicationHandle.in = PouchDB.replicate("http://yankee.davidbanham.com:5984/#{currentListName}", currentListName, {
      live: true
      retry: true
      filter: 'app/irrelevant_deletions'
      batch_size: 1000
      query_params:
        relevant: relevant
    }).on 'change', ->
      updateModel()
    .on 'paused', ->
      $scope.loading = false
    .on 'active', ->
      $scope.loading = true
    .on 'denied', (info) ->
      alert("Permission denied! #{info}")
    .on 'complete', (info) ->
      $scope.loading = false
    .on 'error', (err) ->
      alert("error! #{err.message}")

  $scope.loadPouch = loadPouch = ->
    db = new PouchDB currentListName
    updateModel()

  updateModel = ->
    db.allDocs {include_docs: true}, (err, res) ->
      docIds = res.rows.map (row) ->
        return row.id

      setReplication docIds, currentListName

      innerItems = {}
      unless err?
        for _, row of res.rows
          innerItems[row.id] = row.doc
        $scope.items = items = innerItems
        $scope.$apply()

  $scope.addItem = (item) ->
    $scope.newItem = ''
    for elem in item.split ','
      db.post {name: elem}, (err, res) ->
        console.error err if err?
        updateModel()

  $scope.deleteItem = (item) ->
    db.remove item, (err, res) ->
      console.error "error deleting item", item, err if err?
      delete items[item._id]
      updateModel()

  $scope.resetList = ->
    for id, item of items
      do (id, item) ->
        db.remove item, (err, res) ->
          console.error "error deleting item", item, err if err?
          delete items[id]
          updateModel() if Object.keys(items).length is 0

  loadPouch()

  window.onhashchange = ->
    checkHash()
    loadPouch()
    $scope.$apply()

add_design_docs = (db, cb) ->
  [
    {
      _id: "_design/app",
      filters:
        irrelevant_deletions: ((doc, req) ->
          return true if doc.name
          return false if !req.query.relevant or !req.query.relevant.indexOf
          return true if req.query.relevant.indexOf(doc.id) > -1
          return false
        ).toString()
    }
  ].forEach (doc) ->
    db.post doc, (err) ->
      window.location.reload() if !err #Should only occur on first run, since every subsequent run will err that the document conflicts
