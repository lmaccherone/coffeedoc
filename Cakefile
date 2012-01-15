###
Coffeedoc Cakefile, adapted from [docco](http://jashkenas.github.com/docco/)
by jashkenas
###

{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'build', 'continually build the coffeedoc library with --watch', ->
  coffee = spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()

task 'install', 'install `coffeedoc` globally but from this source using npm', (options) ->
  exec('npm install -g .', (err, stdout, stderr) ->
   if err then console.error stderr
  )
