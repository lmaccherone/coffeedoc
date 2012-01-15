###
Coffeedoc Cakefile, adapted from [docco](http://jashkenas.github.com/docco/)
by jashkenas
###

{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'install', 'install `coffeedoc` globally but from this source using npm', (options) ->
  exec('npm install -g .', (err, stdout, stderr) ->
   if err then console.error stderr
  )
