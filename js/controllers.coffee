currentShoppingList = 'shoppinglist'
app = angular.module('CoffeeModule')
db = null
dbname = "idb://#{currentShoppingList}"

app.controller "ListCtrl", ($scope) ->
  $scope.currentShoppingList = currentShoppingList
  items = {}
  $scope.shoppingList = items

  loadPouch = ->
    Pouch dbname, (err, pouchdb) ->
      alert "Can't open pouch database" if err?
      db = pouchdb
      updateModel()
      pull()
  window.addEventListener 'load', loadPouch, false

  push = ->
    db.compact (err, res) ->
      Pouch.replicate "idb://#{currentShoppingList}", "https://davidbanham.iriscouch.com:6984/#{currentShoppingList}", (err, resp) ->
        console.error err if err?

  pull = ->
    Pouch.replicate "https://davidbanham.iriscouch.com:6984/#{currentShoppingList}", "idb://#{currentShoppingList}", (err, resp) ->
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
