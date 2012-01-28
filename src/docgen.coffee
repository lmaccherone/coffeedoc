###
Documentation generator
=======================

This script generates html documentation from a coffeescript source file
###

# Imports
fs = require('fs')
path = require('path')
eco = require('eco')
showdown = require(__dirname + '/../vendor/showdown').Showdown
coffeedoc = require(__dirname + '/coffeedoc')
parsers = require(__dirname + '/parsers')


# Command line options
OPTIONS =
    '-o, --output': 'Set output directory (default: ./docs)'
    '--commonjs  ': 'Use if target scripts use CommonJS for module loading (default)'
    '--requirejs ': 'Use if target scripts use RequireJS for module loading'
    '--readme    ': 'Generates a draft README.md from the module docstrings'
    '-r, --rout  ': 'Set output file for README.md (defaults to stdout)'

help = ->
    ### Show help message and exit ###
    console.log('Usage: coffeedoc [options] [targets]\n')
    console.log('Options:')
    for flag, description of OPTIONS
        console.log('    ' + flag + ': ' + description)
    process.exit()

opts = process.argv[2...process.argv.length]
if opts.length == 0 then help()

outputdir = 'docs'
readme = false
readmefile = null
parser = null

while opts[0]? and opts[0].substr(0, 1) == '-'
    o = opts.shift()
    switch o
        when '-h', '--help'
            help()
        when '-o', '--output'
            outputdir = opts.shift()
        when '--commonjs'
            parser = new parsers.CommonJSParser()
        when '--requirejs'
            parser = new parsers.RequireJSParser()
        when '--readme'
            readme = true
        when '-r', '--rout'
            readmefile = opts.shift()

if not parser?
    parser = new parsers.CommonJSParser()
if opts.length == 0
    opts = ['.']


renderMarkdown = (obj) ->
    ###
    Helper function that transforms markdown docstring within an AST node
    into html, in place
    ###
    if obj.docstring
        obj.docstring = showdown.makeHtml(obj.docstring)
    return null


# Fetch resources
module_template = fs.readFileSync(__dirname + '/../resources/module.eco', 'utf-8')
index_template = fs.readFileSync(__dirname + '/../resources/index.eco', 'utf-8')
base_css = fs.readFileSync(__dirname + '/../resources/base.css', 'utf-8')
module_css = fs.readFileSync(__dirname + '/../resources/module.css', 'utf-8')
index_css = fs.readFileSync(__dirname + '/../resources/index.css', 'utf-8')


# Get source file paths
sources = []
getSourceFiles = (target) ->
    if path.extname(target) == '.coffee'
        sources.push(target)
    else if fs.statSync(target).isDirectory()
        getSourceFiles(path.join(target, p)) for p in fs.readdirSync(target)
getSourceFiles(o) for o in opts


if sources.length > 0
    modules = []
    
    # Make output directory
    if path.existsSync(outputdir)
        # Recursively delete outputdir if it already exists
        rm = (target) ->
            if fs.statSync(target).isDirectory()
                rm(path.join(target, p)) for p in fs.readdirSync(target)
                fs.rmdirSync(target)
            else
                fs.unlinkSync(target)
        rm(outputdir)
    fs.mkdirSync(outputdir, '755')
    
    # Create README.md
    readmeContents = []

    # Iterate over source scripts
    source_names = (s.replace(/\.coffee$/, '') for s in sources)
    for source, idx in sources
        script = fs.readFileSync(source, 'utf-8')

        # If source is in a subfolder, make a matching subfolder in outputdir
        csspath = 'resources/'
        if source.indexOf('/') != -1
            docpath = outputdir
            sourcepath = source.split('/')
            for dir in sourcepath[0...sourcepath.length - 1]
                csspath = '../' + csspath
                docpath = path.join(docpath, dir)
                if not path.existsSync(docpath)
                    fs.mkdirSync(docpath, '755')

        # Fetch documentation information
        documentation =
            filename: source_names[idx]
            module_name: path.basename(source)
            module: coffeedoc.documentModule(script, parser)
            csspath: csspath

        # Check for classes inheriting from classes in other modules
        for cls in documentation.module.classes when cls.parent
            clspath = cls.parent.split('.')
            if clspath.length > 1
                prefix = clspath.shift()
                if prefix of documentation.module.deps
                    module_path = documentation.module.deps[prefix]
                    if path.dirname(source) + '/' + module_path in source_names
                        cls.parent_module = module_path
                        cls.parent_name = clspath.join('.')

        # Append to README.md
        readmeContents.push(documentation.module.docstring)
        
        # Convert markdown to html
        skipModuleFunctions = []
        renderMarkdown(documentation.module)
        for c in documentation.module.classes
            renderMarkdown(c)
            skipStaticMethods = []
            skipInstanceMethods = []
            for m, idx in c.staticmethods
              if path.extname(m.name)[1..1] == '_'
                skipStaticMethods.unshift(idx)
              else
                renderMarkdown(m)
            for i in skipStaticMethods
              c.staticmethods.splice(i, 1)
            for m, idx in c.instancemethods
              if m.name[0..0] == '_'
                skipInstanceMethods.unshift(idx)
              else
                renderMarkdown(m) for m in c.instancemethods
            for i in skipInstanceMethods
              c.instancemethods.splice(i, 1)
        for f, idx in documentation.module.functions
          if f.name[0..0] == '_'
            skipModuleFunctions.unshift(idx)
          else
            renderMarkdown(f) for f in documentation.module.functions
        for i in skipModuleFunctions
          documentation.module.functions.splice(i, 1)

        # Generate docs
        html = eco.render(module_template, documentation)

        # Write to file
        fs.writeFile(path.join(outputdir, documentation.filename + '.html'), html)

        # Save to modules array for the index page
        modules.push(documentation)

    # Write css stylesheets to `resources/`
    resourcesdir = path.join(outputdir, 'resources')
    fs.mkdir resourcesdir, '755', ->
        fs.writeFile(path.join(resourcesdir, 'base.css'), base_css)
        fs.writeFile(path.join(resourcesdir, 'module.css'), module_css)
        fs.writeFile(path.join(resourcesdir, 'index.css'), index_css)

    # Make index page
    index = eco.render(index_template, modules: modules)
    fs.writeFile(path.join(outputdir, 'index.html'), index)
    
    # Write README.md
    if readmefile?
      fs.writeFile(readmefile, readmeContents.join('\n'))
    else
      process.stdout.write(readmeContents.join('\n'))
            

