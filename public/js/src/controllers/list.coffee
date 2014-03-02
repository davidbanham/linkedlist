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
    db = new PouchDB currentListName
    updateModel()
    pull()

  push = ->
    db.compact (err, res) ->
      $scope.loading = true
      db.replicate.to "http://yankee.davidbanham.com:5984/#{currentListName}", {continuous: true, create_target: true, onChange: updateModel}, (err, resp) ->
        $scope.loading = false
        console.error err if err?

  pull = ->
    $scope.loading = true
    db.replicate.from "http://yankee.davidbanham.com:5984/#{currentListName}", {continuous: true, onChange: updateModel}, (err, resp) ->
      $scope.loading = false
      console.error "pull failed with", err if err?
      updateModel()

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
    db.post {name: item}, (err, res) ->
      console.error err if err?
      updateModel()
      push()

  $scope.deleteItem = (item) ->
    db.remove item, (err, res) ->
      console.error "error deleting item", item, err if err?
      delete items[item._id]
      updateModel()
      push()

  $scope.resetList = ->
    for id, item of items
      do (id, item) ->
        db.remove item, (err, res) ->
          console.error "error deleting item", item, err if err?
          delete items[id]
          updateModel() if Object.keys(items).length is 0
          push() if Object.keys(items).length is 0

  loadPouch()

  window.onhashchange = ->
    checkHash()
    loadPouch()
    $scope.$apply()

  window.addEventListener 'online', ->
    console.log 'back online'
    pull()
    push()
