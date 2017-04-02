require 'resedit/app/app_command'
require 'resedit/mz/mz'

module Resedit

    class MZCommand < AppCommand
        def initialize
            super(['mz'])
            addParam('cmd', "mz command","info")
            addParam('p1', "mz command parameter","")
            addParam('p2', "mz command parameter","")
            addParam('p3', "mz command parameter","")
            addParam('p4', "mz command parameter","")
            addParam('p5', "mz command parameter","")
            addOption('--help', '-h', false, 'help on mz commands')
            @cmds = {
                "help"=>[method(:help), "show help on mz commands", {"command" => "command to show help on"}],
                "info"=>[method(:info), "print info about mz objects", {"what" => "files/header/reloc"}],
                "use"=>[method(:use), "select mz file", {"file" => "path to mz file"}],
                "close"=>[method(:use), "close file", {"file" => "path or id of file to close"}],
            }
            @files = []
            @cur = nil
        end

        def help(params)
            if params['command']
                raise "Unknown mz command: " + params['command'] if !@cmds[params['command']]
                cmd = @cmds[params['command']]
                puts(params['command'] + "\t-" + cmd[1])
                if cmd[2]
                    puts
                    puts("params:")
                    cmd[2].each{|k,v|
                        puts k + "\t-" + v
                    }
                end
            else
                puts("available mz commands:")
                @cmds.each{|k,v|
                    puts k + "\t-" + v[1]
                }
            end
            puts
        end

        def getfile(id)
            return @cur if id == nil
            i,res=MZ.s2i(id, false)
            if res
                raise "Bad file id: " + id if @files.length < i
                return @files[i]
            end
            @files.each{|mz|
                return mz if mz.is?(id)
            }
            return nil
        end


        def info(params=nil)
            what = params['what'] if params
            if what == nil || what == "files"
                if @files.length != 0
                    curid = -1
                    @files.each.with_index{|mz,i|
                        puts "#{i}:\t#{mz.path}"
                        curid=i if mz == @cur
                    }
                    puts
                    puts "Current file:"
                    puts "#{curid}:\t#{@cur.path}"
                    puts
                else
                    puts "No files opened"
                end
            else
                raise "MZ file not loaded" if !@cur
                @cur.info(what)
            end
        end


        def use(params)
            mz = getfile(params['file'])
            if mz==nil
                mz = MZ.new(params['file'])
                @files+=[mz]
            end
            @cur = mz
            info()
        end

        def close(params)
            mz = getfile(params['file'])
            raise "File not found: "+fn if nil == fl
            @files -= [mz]
            @cur = nil if @cur == mz
            mz.close()
            mz = nil
            @cur = @files[0] if !@cur && @files.length>0
            info()
        end


        def job(params)
            cmd = params['cmd']
            cmd = 'help' if params['--help']
            raise "Unknown command: "+cmd if !@cmds[cmd]
            scmd = @cmds[cmd]
            if scmd[2]
                scmd[2].keys.each.with_index{|k,i|
                    params[k] = params["p#{i+1}"]
                    params[k] = nil if params[k].length == 0
                }
            end
            scmd[0].call(params)
        end

    end

end
