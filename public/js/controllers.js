(function() {
  var add_design_docs, app, db;

  app = angular.module('CoffeeModule');

  db = 'supermarket';

  app.controller("ListCtrl", function($scope) {
    var checkHash, chooseDb, currentListName, debounce, globalishReplicationHandle, items, loadPouch, setReplication, updateHash, updateModel;
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
    globalishReplicationHandle = {
      out: {
        cancel: function() {}
      },
      "in": {
        cancel: function() {}
      }
    };
    setReplication = function(relevant, currentListName) {
      globalishReplicationHandle.out.cancel();
      globalishReplicationHandle["in"].cancel();
      globalishReplicationHandle.out = PouchDB.replicate(currentListName, "http://yankee.davidbanham.com:5984/" + currentListName, {
        live: true,
        retry: true,
        batch_size: 1000
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
      return globalishReplicationHandle["in"] = PouchDB.replicate("http://yankee.davidbanham.com:5984/" + currentListName, currentListName, {
        live: true,
        retry: true,
        filter: 'app/irrelevant_deletions',
        batch_size: 1000,
        query_params: {
          relevant: relevant
        }
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
    $scope.loadPouch = loadPouch = function() {
      db = new PouchDB(currentListName);
      return updateModel();
    };
    updateModel = function() {
      return db.allDocs({
        include_docs: true
      }, function(err, res) {
        var docIds, innerItems, row, _, _ref;
        docIds = res.rows.map(function(row) {
          return row.id;
        });
        setReplication(docIds, currentListName);
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
    return window.onhashchange = function() {
      checkHash();
      loadPouch();
      return $scope.$apply();
    };
  });

  add_design_docs = function(db, cb) {
    return [
      {
        _id: "_design/app",
        filters: {
          irrelevant_deletions: (function(doc, req) {
            if (doc.name) {
              return true;
            }
            if (!req.query.relevant || !req.query.relevant.indexOf) {
              return false;
            }
            if (req.query.relevant.indexOf(doc.id) > -1) {
              return true;
            }
            return false;
          }).toString()
        }
      }
    ].forEach(function(doc) {
      return db.post(doc, function(err) {
        if (!err) {
          return window.location.reload();
        }
      });
    });
  };

}).call(this);
