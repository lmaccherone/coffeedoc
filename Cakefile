###
Coffeedoc Cakefile, adapted from [docco](http://jashkenas.github.com/docco/)
by jashkenas, forked by Larry Maccherone
###

{spawn, exec} = require 'child_process'


run = (command, options, next) ->
  if options? and options.length > 0
    command += ' ' + options.join(' ')
  exec(command, (error, stdout, stderr) ->
    if stderr.length > 0
      console.log("Stderr exec'ing command '#{command}'...\n" + stderr)
    if error?
      console.log('exec error: ' + error)
    if next?
      next(stdout)
    else
      if stdout.length > 0
        console.log("Stdout exec'ing command '#{command}'...\n" + stdout)
  )


task('install', 'Install globally but from this source using npm', () ->
  process.chdir(__dirname)
  run('npm install -g .')
)

task('publish', 'Publish to npm', () ->
  process.chdir(__dirname)
  run('npm publish .')
)