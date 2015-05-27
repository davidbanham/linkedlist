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

  $scope.loadPouch = loadPouch = ->
    db = new PouchDB currentListName,
      auto_compaction: true
    updateModel()

    PouchDB.sync(currentListName, "http://yankee.davidbanham.com:5984/#{currentListName}", {
      live: true
      retry: true
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

  updateModel = ->
    db.allDocs {include_docs: true}, (err, res) ->
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
