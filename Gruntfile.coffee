module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    coffee:
      compile:
        files:
          'public/js/controllers.js': ['public/js/src/controllers/*.coffee']
      compile_tests:
        files:
          'public/js/test_controllers.js': ['public/js/test/controllers/*.coffee']
    watch:
      scripts:
        files: 'public/js/src/**/*.coffee'
        tasks: ['coffee:compile', 'coffee:compile_tests']
        options:
          spawn: true
      tests:
        files: 'public/js/test/**/*.coffee'
        tasks: ['coffee:compile_tests']
        options:
          spawn: true
    karma:
      unit:
        config: 'config/karma.conf.coffee'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-notify'
  grunt.loadNpmTasks 'grunt-karma'

  grunt.registerTask 'default', ['coffee']
  grunt.registerTask 'test', ['karma']
