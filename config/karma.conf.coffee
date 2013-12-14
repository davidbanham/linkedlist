module.exports = (config) ->
  config.set
    basePath: '../public'

    files: [
      'lib/angular/angular.min.js'
      'lib/angular-mocks/angular-mocks.js'
      'js/pouchdb-nightly.min.js'
      'js/app.js'
      'js/controllers.js'
      'js/test_controllers.js'
    ]
    autoWatch: true
    frameworks: ['jasmine']
    browsers: ['Chrome']
    plugins: [
      'karma-chrome-launcher'
      'karma-jasmine'
    ]
