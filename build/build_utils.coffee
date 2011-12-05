fs = require 'fs'
{exec} = require 'child_process'
require './string_extensions'
require '../src/string_extensions'
require '../src/array_extensions'

class BuildUtils
  slider_file: 'jquery.rambling.slider.coffee'

  log: (string) ->
    console.log string.as_console_message()

  log_raw: (string) ->
    console.log string

  error_handler: (err, stdout, stderr) ->
    console.log stdout if stdout
    console.log stderr if stderr
    throw err if err

  process: (content, callback) ->
    self = @
    fs.writeFile "lib/#{self.slider_file}", content.join("\n\n"), 'utf8', (err) ->
      self.error_handler err
      self.log "Building `src/#{self.slider_file}`"
      exec "coffee -c lib/#{self.slider_file}", (err, stdout, stderr) ->
        self.error_handler err, stdout, stderr
        fs.unlink "lib/#{self.slider_file}", (err) ->
          self.error_handler err
          self.log "Done. Output in `lib/#{self.slider_file.replace(/coffee/, 'js')}`"
          callback()

  compile: (callback) ->
    self = @
    @combine_source_files (content) ->
      self.process content, callback

  file_sorter: (first, second) ->
    return -1 if first is 'comments.coffee'
    return 1 if second is 'comments.coffee'
    return -1 if second is 'rambling.slider.transitions.coffee'
    return 1 if first is 'rambling.slider.transitions.coffee'
    return -1 if second is 'rambling.slider.coffee'
    return 1 if first is 'rambling.slider.coffee'
    return -1 if first < second
    return 1 if first > second
    0

  combine_source_files: (callback) ->
    self = @
    fs.readdir './src', (err, files) ->
      self.error_handler err
      content = []
      contentAdded = 0

      files = files.where (file) -> not file.startsWith '.'
      files = files.sort self.file_sorter

      self.log "Combining following files into `src/#{self.slider_file}`:\n  #{files.join('\n  ')}"
      for file, index in files then do (file, index) ->
        fs.readFile "./src/#{file}", 'utf8', (err, fileContent) ->
          self.error_handler err
          content[index] = fileContent
          contentAdded++

          callback(content) if contentAdded is files.length

global.BuildUtils = BuildUtils
