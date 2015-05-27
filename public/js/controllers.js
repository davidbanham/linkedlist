(function() {
  var app, db;

  app = angular.module('CoffeeModule');

  db = 'supermarket';

  app.controller("ListCtrl", function($scope) {
    var checkHash, chooseDb, currentListName, debounce, items, loadPouch, updateHash, updateModel;
    currentListName = 'supermarket';
    $scope.chooseDb = chooseDb = function(name) {
      $scope.currentListName = currentListName = name;
      return updateHash(name);
    };
    updateHash = function(name) {
      return window.location.hash = "#/" + currentListName;
    };
    debounce = null;
    $scope.$watch('currentListName', function(newVal, oldVal) {
      clearTimeout(debounce);
      return debounce = setTimeout(function() {
        return chooseDb(newVal);
      }, 500);
    });
    checkHash = function() {
      var targetName;
      targetName = window.location.hash.split('#/')[1];
      if (targetName === void 0) {
        targetName = 'supermarket';
      }
      return chooseDb(targetName);
    };
    checkHash();
    $scope.currentListName = currentListName;
    items = {};
    $scope.items = items;
    $scope.loadPouch = loadPouch = function() {
      db = new PouchDB(currentListName);
      updateModel();
      return PouchDB.sync(currentListName, "http://yankee.davidbanham.com:5984/" + currentListName, {
        live: true,
        retry: true
      }).on('change', function() {
        return updateModel();
      }).on('paused', function() {
        return $scope.loading = false;
      }).on('active', function() {
        return $scope.loading = true;
      }).on('denied', function(info) {
        return alert("Permission denied! " + info);
      }).on('complete', function(info) {
        return $scope.loading = false;
      }).on('error', function(err) {
        return alert("error! " + err.message);
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
      var elem, _i, _len, _ref, _results;
      $scope.newItem = '';
      _ref = item.split(',');
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        elem = _ref[_i];
        _results.push(db.post({
          name: elem
        }, function(err, res) {
          if (err != null) {
            console.error(err);
          }
          return updateModel();
        }));
      }
      return _results;
    };
    $scope.deleteItem = function(item) {
      return db.remove(item, function(err, res) {
        if (err != null) {
          console.error("error deleting item", item, err);
        }
        delete items[item._id];
        return updateModel();
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
              return updateModel();
            }
          });
        })(id, item));
      }
      return _results;
    };
    loadPouch();
    window.onhashchange = function() {
      checkHash();
      loadPouch();
      return $scope.$apply();
    };
  });

}).call(this);
