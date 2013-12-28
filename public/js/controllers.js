(function() {
  var app, currentShoppingList, db, dbname;

  currentShoppingList = 'shoppinglist';

  app = angular.module('CoffeeModule');

  db = null;

  dbname = "idb://" + currentShoppingList;

  app.controller("ListCtrl", function($scope) {
    var items, loadPouch, pull, push, updateModel;
    $scope.currentShoppingList = currentShoppingList;
    items = {};
    $scope.shoppingList = items;
    $scope.loadPouch = loadPouch = function() {
      return Pouch(dbname, function(err, pouchdb) {
        if (err != null) {
          alert("Can't open pouch database");
        }
        $scope.db = db = pouchdb;
        updateModel();
        return pull();
      });
    };
    window.addEventListener('load', loadPouch, false);
    push = function() {
      return db.compact(function(err, res) {
        $scope.loading = true;
        return db.replicate.to("http://yankee.davidbanham.com:5984/" + currentShoppingList, {
          continuous: true,
          create_target: true,
          onChange: updateModel,
          complete: updateModel
        }, function(err, resp) {
          $scope.loading = false;
          if (err != null) {
            return console.error(err);
          }
        });
      });
    };
    pull = function() {
      $scope.loading = true;
      return db.replicate.from("http://yankee.davidbanham.com:5984/" + currentShoppingList, {
        continuous: true,
        onChange: updateModel,
        complete: updateModel
      }, function(err, resp) {
        $scope.loading = false;
        if (err != null) {
          console.error("pull failed with", err);
        }
        return updateModel();
      });
    };
    updateModel = function() {
      return db.allDocs({
        include_docs: true
      }, function(err, res) {
        var id, row, _ref;
        if (err == null) {
          _ref = res.rows;
          for (id in _ref) {
            row = _ref[id];
            items[row.id] = row.doc;
          }
          return $scope.$apply();
        }
      });
    };
    $scope.addItem = function(item) {
      return db.post({
        name: item
      }, function(err, res) {
        if (err != null) {
          console.error(err);
        }
        updateModel();
        return push();
      });
    };
    $scope.deleteItem = function(item) {
      return db.remove(item, function(err, res) {
        if (err != null) {
          console.error("error deleting item", item, err);
        }
        delete items[item._id];
        updateModel();
        return push();
      });
    };
    $scope.resetList = function() {
      var id, item, _results;
      _results = [];
      for (id in items) {
        item = items[id];
        _results.push((function(id, item) {
          return db.remove(item, function(err, res) {
            if (err != null) {
              console.error("error deleting item", item, err);
            }
            delete items[id];
            if (Object.keys(items).length === 0) {
              updateModel();
            }
            if (Object.keys(items).length === 0) {
              return push();
            }
          });
        })(id, item));
      }
      return _results;
    };
    return setInterval(updateModel, 10000);
  });

}).call(this);
