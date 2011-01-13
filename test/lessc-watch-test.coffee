vows = require 'vows'
{equal,ok} = require 'assert'
{exec,spawn} = require 'child_process'
{resolve} = require 'path'
{mkdirSync,unlinkSync,rmdirSync,writeFileSync,readFileSync,statSync} = require 'fs'
log = console.log.bind console

compileTime = 2000
defer = (mult, f)->
   setTimeout f,compileTime*mult

USAGE = '\nlessc-watch [src directory] [output directory]\n\n'
exec_lesscwatch = (args,done)->
   exec "coffee #{__dirname}/../src/lessc-watch.coffee #{args.join ' '}", done
spawn_lesscwatch = (args)->
   l = spawn "coffee", ["#{__dirname}/../src/lessc-watch.coffee"].concat(args)
   l.stdout.on 'data', (data)-> log "\n[lessc-watch.coffee] #{data}\n"
   l

vows.describe('lessc-watch').addBatch(
   'When': do->
      mockLess = '.test{color:#000;}'
      should = (shouldmsg,{setup, verify})->
         context =
            topic: ->
               callback = @callback.bind(this)
               exec 'mktemp -d /tmp/lessc-watch-test-SRC.XXXXXXXX', (e,dir,se)->
                  tmpSrcDir = dir.trim()
                  exec 'mktemp -d /tmp/lessc-watch-test-OUT.XXXXXXXX', (e,dir,se)->
                     tmpOutDir = dir.trim()
                     lesscProc = spawn_lesscwatch [tmpSrcDir, tmpOutDir]
                     o = {src:tmpSrcDir,out:tmpOutDir,proc:lesscProc}
                     setup o, ->
                        defer 1, ->callback null, o
               undefined
            teardown: ({src,out,proc})->
               proc.kill() if proc
               exec "rm -rf #{src} #{out}"
         context["... #{shouldmsg}"] = verify
         context

      'the src directory contains a LESS file': should 'compile and placed it in the output directory'
         setup:  ({src},done)->
            writeFileSync src+'/test.less', '.test{color:#000;}', 'utf8'
            done()
         verify: ({src,out})->
            equal readFileSync(out+'/test.css','utf8'),
               '''
               .test {
                 color: #000;
               }
               
               '''

      'the src directory contains another directory': should 'create it in the output directory'
         setup:  ({src},done)->
            mkdirSync resolve(src,'testdir'), 0755
            done()
         verify: ({src,out})->
            ok statSync(resolve(out,'testdir')).isDirectory()

      'a directory is removed': should 'remove it from the output directory'
         setup:  ({src},done)->
            mkdirSync "#{src}/testdir", 0755
            done()
            defer .5, -> rmdirSync "#{src}/testdir"
         verify: ({src,out})->
            isdir = false
            try isdir = statSync("#{out}/testdir").isDirectory()
            ok !isdir

      'a LESS file is removed': should 'remove it from the output directory'
         setup:  ({src,out},done)->
            writeFileSync src+'/test.less', '.test{color:#000;}', 'utf8'
            done()
            defer .5, -> unlinkSync "#{src}/test.less"
         verify: ({src,out})->
            try sync = statSync("#{out}/test.css")
            ok not sync


      ###
      # fs.watchFile apparently don't notice when sub directory is added... bummer
      
      'a directory is added': should 'create it in the output directory'
         setup:  ({src},done)->
            done()
            defer .5, -> mkdirSync resolve(src,'testdir'), 0755
         verify: ({src,out})->
            ok statSync(resolve(out,'testdir')).isDirectory()
      ###

      'the src directory contains directories with other directories': should 'created it in the output directory'
         setup:  ({src},done)->
            mkdirSync resolve(src,'testdir'), 0755
            mkdirSync resolve(src,'testdir','nested_testdir'), 0755
            done()
         verify: ({src,out})->
            ok statSync(resolve(out,'testdir')).isDirectory()
            ok statSync(resolve(out,'testdir','nested_testdir')).isDirectory()

      'a LESS file is added': should 'compile and placed it in the output directory'
         setup:  ({src},done)->
            done()
            defer .5, (-> writeFileSync src+'/test.less', '.test{color:#000;}', 'utf8')
         verify: ({src,out})->
            equal readFileSync(out+'/test.css','utf8'),
               '''
               .test {
                 color: #000;
               }
               
               '''

      'a LESS file is changed': should 'recompile it'
         setup:  ({src},done)->
            writeFileSync src+'/test.less', '.test{color:#000;}', 'utf8'
            done()
            defer .5, (->exec "echo '.test2 {color:#FFF;}' >> #{src}/test.less")

         verify: ({src,out})->
            equal readFileSync(out+'/test.css','utf8'),
               '''
               .test {
                 color: #000;
               }
               .test2 {
                 color: #FFF;
               }

               '''

      'a nested LESS file is changed': should 'recompile it'
         setup:  ({src},done)->
            mkdirSync "#{src}/testdir", 0755
            mkdirSync "#{src}/testdir/nested_testdir", 0755
            writeFileSync "#{src}/testdir/nested_testdir/test.less", '.test{color:#000;}', 'utf8'
            done()
            defer .5, (->exec "echo '.test2 {color:#FFF;}' >> #{src}/testdir/nested_testdir/test.less")

         verify: ({src,out})->
            equal readFileSync("#{out}/testdir/nested_testdir/test.css",'utf8'),
               '''
               .test {
                 color: #000;
               }
               .test2 {
                 color: #FFF;
               }

               '''

   'When given invalid arguments:': do ->
      doesNotExist = (name, path)->"#{name} '#{path}' does not exist\n#{USAGE}"
      isNotDir = (name,path)->"#{name} '#{path}' is not a directory\n#{USAGE}"
      shouldPrint = (expectedOut)->
         context =
            topic: ->
               argString = @context.name
               exec_lesscwatch(
                  if argString == '' then [] else argString.split(/[ ]+/).map((_)->resolve(__dirname, _)),
                  @callback
               )
               undefined
         context["Should print:\n#{expectedOut}"] = (e,so,se)->
            equal so, expectedOut
         context

      '': shouldPrint "src directory is empty\n#{USAGE}"
      'mock/less_dir': shouldPrint "output directory is empty\n#{USAGE}"
      'bogus_src_dir mock/less_dir': shouldPrint doesNotExist( 'src directory', resolve(__dirname,'bogus_src_dir') )
      'mock/less_dir bogus_out_dir': shouldPrint doesNotExist( 'output directory', resolve(__dirname,'bogus_out_dir') )
      'mock/file mock/less_dir': shouldPrint isNotDir( 'src directory', resolve(__dirname,'mock/file') )
      'mock/less_dir mock/file': shouldPrint isNotDir( 'output directory', resolve(__dirname,'mock/file') )


).export module
