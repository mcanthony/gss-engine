module.exports = ->
  # Project configuration
  @initConfig
    pkg: @file.readJSON 'package.json'

    clean:
      nuke_components:
        src: ['components/*/']
      nuke_bower:
        src: ['bower_components']
      nuke_built:
        src: ['browser']

    exec:
      component_install:
        command: 'node ./node_modules/component/bin/component install'
      component_build:
        command: 'node ./node_modules/component/bin/component build -o browser -n gss -s gss -c'

    # JavaScript minification for the browser
    uglify:
      options:
        report: 'min'
      worker:
        files:
          './worker/gss-solver.min.js': ['./worker/gss-solver.js']
      engine:
        files:
          './browser/gss.min.js': ['./browser/gss.js']

    # Automated recompilation and testing when developing
    watch:
      'build-fast':
        files: ['spec/*.coffee','spec/**/*.coffee', 'src/*.coffee', 'src/**/*.coffee']
        tasks: ['build-fast']
      build:
        files: ['spec/*.coffee','spec/**/*.coffee', 'src/*.coffee', 'src/**/*.coffee']
        tasks: ['build']
      test:
        files: ['spec/*.coffee', 'src/*.coffee']
        tasks: ['test']

    # Syntax checking
    coffeelint:
      src:
        files:
          src: ['src/*.coffee', 'src/**/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'
          'no_trailing_whitespace':
            level: 'ignore'
      spec:
        files:
          src: ['spec/*.coffee']
        options:
          'max_line_length':
            level: 'ignore'
          'no_trailing_whitespace':
            level: 'ignore'
          'no_backticks':
            level: 'ignore'
    
    # CoffeeScript compilation
    coffee:
      src:
        options:
          bare: true
        expand: true
        cwd: 'src'
        src: ['**.coffee', '**/*.coffee']
        dest: 'lib'
        ext: '.js'

      spec:
        options:
          bare: true
        expand: true
        cwd: 'spec'
        src: ['**.coffee', '**/*.coffee']
        dest: 'spec'
        ext: '.js'

    # Worker process concatenation
    concat:
      worker:
        src: ['vendor/c.js', 'lib/Thread.js', 'lib/Worker.js']
        dest: 'worker/gss-solver.js'
      ###
      vendors:
        options:
          banner: 'module.exports = function(){'
          footer: '};'
        src: ['vendor/c.js', 'vendor/sidetable.js', 'vendor/MutationObserver.js']
        dest: 'lib/vendor.js'
      ###
      ###
      blob:
        options:
          banner: 'module.exports = window.URL.createObjectURL(new Blob(['
          footer: '],{type:"text/javascript"}));'
          process: (src, filepath) ->
            return JSON.stringify(src) # only works with one file
        src: ['worker/gss-solver.min.js']
        dest: 'lib/WorkerBlobUrl.js'
      ###
        

    # BDD tests on browser
    mocha_phantomjs:
      all: ['spec/runner.html']

    # Cross-browser testing
    connect:
      server:
        options:
          base: ''
          port: 9999

    'saucelabs-mocha':
      all:
        options:
          urls: ['http://127.0.0.1:9999/spec/runner.html']
          browsers: [
            browserName: 'chrome'
          ,
            browserName: 'firefox'
          ,
            browserName: 'safari'
            platform: 'OS X 10.8'
            version: '6'
          ,
            browserName: 'opera'
          ,
            browserName: 'internet explorer'
            platform: 'WIN8'
            version: '10'
          ,
            browserName: 'internet explorer'
            platform: 'WIN7'
            version: '9'
          ]
          build: process.env.TRAVIS_JOB_ID
          testname: 'GSS engine browser tests'
          tunnelTimeout: 5
          concurrency: 3
          detailedError: true

  # Grunt plugins used for building
  @loadNpmTasks 'grunt-contrib-coffee'
  @loadNpmTasks 'grunt-contrib-concat'
  @loadNpmTasks 'grunt-contrib-uglify'
  @loadNpmTasks 'grunt-contrib-clean'
  @loadNpmTasks 'grunt-exec'

  # Grunt plugins used for testing
  @loadNpmTasks 'grunt-coffeelint'
  @loadNpmTasks 'grunt-mocha-phantomjs'
  @loadNpmTasks 'grunt-contrib-watch'

  # Cross-browser testing in the cloud
  @loadNpmTasks 'grunt-contrib-connect'
  @loadNpmTasks 'grunt-saucelabs'

  @registerTask 'build-fast', ['coffee', 'concat:worker', 'exec:component_build']
  @registerTask 'build', ['coffee', 'concat:worker', 'uglify:worker', 'exec', 'uglify:engine']
  @registerTask 'test', ['build', 'coffeelint', 'mocha_phantomjs']
  @registerTask 'crossbrowser', ['build', 'coffeelint', 'connect', 'saucelabs-mocha']
  @registerTask 'default', ['build']
  @registerTask 'nuke', ['clean']
