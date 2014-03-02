app = angular.module 'CoffeeModule'

app.directive 'contenteditable', ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, element, attrs, ngModel) ->
    return if !ngModel

    ngModel.$render = ->
      element.html ngModel.$viewValue or ''

      element.on 'blur keyup change', ->
        console.log 'wat'
        scope.$apply read

      read = ->
        html = element.html()
        if attrs.stripBr && html is '<br>'
          html = ''

        ngModel.$setViewValue html

      read()

