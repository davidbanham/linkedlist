(function() {
  var app, db;

  app = angular.module('CoffeeModule');

  db = null;

  app.controller("ListCtrl", function($scope) {
    var chooseDb, currentListName, items, loadPouch, pull, push, updateModel;
    currentListName = null;
    chooseDb = function() {
      return $scope.currentListName = currentListName = window.location.hash.split('#/')[1] || 'supermarket';
    };
    chooseDb();
    $scope.currentListName = currentListName;
    items = {};
    $scope.items = items;
    $scope.loadPouch = loadPouch = function() {
      db = new PouchDB(currentListName);
      updateModel();
      return pull();
    };
    push = function() {
      return db.compact(function(err, res) {
        $scope.loading = true;
        return db.replicate.to("http://yankee.davidbanham.com:5984/" + currentListName, {
          continuous: true,
          create_target: true,
          onChange: updateModel
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
      return db.replicate.from("http://yankee.davidbanham.com:5984/" + currentListName, {
        continuous: true,
        onChange: updateModel
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
        var innerItems, row, _, _ref;
        innerItems = {};
        if (err == null) {
          _ref = res.rows;
          for (_ in _ref) {
            row = _ref[_];
            innerItems[row.id] = row.doc;
          }
          $scope.items = items = innerItems;
          return $scope.$apply();
        }
      });
    };
    $scope.addItem = function(item) {
      $scope.newItem = '';
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
    loadPouch();
    window.onhashchange = function() {
      chooseDb();
      loadPouch();
      return $scope.$apply();
    };
    return window.addEventListener('online', function() {
      console.log('back online');
      pull();
      return push();
    });
  });

}).call(this);
