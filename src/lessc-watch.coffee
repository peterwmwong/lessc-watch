{watchFile,unwatchFile,stat,statSync,readdir,unlink} = require 'fs'
{exists,resolve} = require 'path'
{EventEmitter} = require 'events'
{exec} = require 'child_process'
log = console.log.bind console
_exec = (cmd,done)->
   exec cmd, done


printUsage = -> log '\nlessc-watch [src directory] [output directory]\n'

# Check src and out arguments
checkResolveDir = (argname, arg)->
   p = resolve arg
   try
      unless arg?.slice(0,-1)?
         throw "#{argname} is empty"

      isDir = false
      try isDir = statSync(p).isDirectory()
      catch e
         throw "#{argname} '#{p}' does not exist"

      unless isDir then throw "#{argname} '#{p}' is not a directory"

      p+'/'
   catch e
      log e.message or e
      printUsage()


if (srcdir = checkResolveDir('src directory', process.argv[2])) and (outdir = checkResolveDir('output directory', process.argv[3]))
   srcToOut = (src)-> resolve outdir, src.slice(srcdir.length)
   compileLess = (srcpath)->
      outpath = srcToOut srcpath
      _exec "lessc #{srcpath} #{outpath.slice(0,-5)}.css", (e,so,se)->
         log "[lessc #{srcpath} #{outpath}] OUT> #{so}" if so
         log "[lessc #{srcpath} #{outpath}] ERR> #{se}" if se
   files = {}
   dirs = {}

   _watchdir = do->
      handlefiles = (p,e,files)->
         if not files
            debugger

         for f in files
            f = resolve p,f
            do(f)->
               stat f, (e,s)->
                  unless e
                     if s.isFile()
                        _watchfile f
                     else
                        _watchdir f
                  else
                     log "stat fail on f='#{f}':",e
      (p)->
         if not dirs[p]
            watchFile( p, dirs[p] = (stat)->
               exists p, (yeah)->
                  if not yeah
                     delete dirs[p]
                     unwatchFile p
                     _exec "rm -rf #{srcToOut p}"
                  else
                     readdir p, handlefiles.bind(null,p)
            )
            _exec "mkdir -p #{srcToOut p}", (e,so,se)->
               if e then log "[ERROR] could not execute `mkdir -p #{srcToOut p}`"
               readdir p, handlefiles.bind(null,p)

   _watchfile = (p)->
      if p.slice(-5) == '.less' and not files[p]
         watchFile( p, files[p] = (stat)->
            exists p, (yeah)->
               if not yeah
                  delete files[p]
                  unwatchFile p
                  unlink "#{srcToOut p.slice(0,-5)}.css"
               else
                  compileLess p
         )
         compileLess p

   _watchdir srcdir
