(function() {
  var app;

  app = angular.module('CoffeeModule');

  app.directive('contenteditable', function() {
    return {
      restrict: 'A',
      require: '?ngModel',
      link: function(scope, element, attrs, ngModel) {
        if (!ngModel) {
          return;
        }
        return ngModel.$render = function() {
          var read;
          element.html(ngModel.$viewValue || '');
          element.on('blur keyup change', function() {
            return scope.$apply(read);
          });
          read = function() {
            var html;
            html = element.html();
            if (attrs.stripBr && html === '<br>') {
              html = '';
            }
            return ngModel.$setViewValue(html);
          };
          return read();
        };
      }
    };
  });

}).call(this);
