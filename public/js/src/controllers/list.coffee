currentShoppingList = 'shoppinglist'
app = angular.module('CoffeeModule')
db = null
dbname = "idb://#{currentShoppingList}"

app.controller "ListCtrl", ($scope) ->
  $scope.currentShoppingList = currentShoppingList
  items = {}
  $scope.shoppingList = items

  $scope.loadPouch = loadPouch = ->
    Pouch dbname, (err, pouchdb) ->
      alert "Can't open pouch database" if err?
      $scope.db = db = pouchdb
      updateModel()
      pull()
  window.addEventListener 'load', loadPouch, false

  push = ->
    db.compact (err, res) ->
      $scope.loading = true
      db.replicate.to "http://yankee.davidbanham.com:5984/#{currentShoppingList}", {continuous: true, create_target: true, onChange: updateModel, complete: updateModel}, (err, resp) ->
        $scope.loading = false
        console.error err if err?

  pull = ->
    $scope.loading = true
    db.replicate.from "http://yankee.davidbanham.com:5984/#{currentShoppingList}", {continuous: true, onChange: updateModel, complete: updateModel}, (err, resp) ->
      $scope.loading = false
      console.error "pull failed with", err if err?
      updateModel()

  updateModel = ->
    db.allDocs {include_docs: true}, (err, res) ->
      unless err?
        for id, row of res.rows
          items[row.id] = row.doc
        $scope.$apply()

  $scope.addItem = (item) ->
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

  setInterval ->
    updateModel()
  , 10000
