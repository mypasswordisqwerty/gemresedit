require 'resedit/app/app'
require 'resedit/app/app_command'
require 'resedit/mz/mz'
require 'resedit/mz/mzenv'


module Resedit

    class MZCommand < AppCommand
        def initialize
            super(['mz'])
            addParam('cmd', "mz command","")
            addParam('p1', "mz command parameter","")
            addParam('p2', "mz command parameter","")
            addParam('p3', "mz command parameter","")
            addParam('p4', "mz command parameter","")
            addParam('p5', "mz command parameter","")
            addOption('help', 'h', nil, 'help on mz commands')
            @cmds = {
                "help"=>[method(:help), "show help on mz commands", {"command" => "command to show help on"}],
                "use"=>[method(:use), "select mz file", {"file" => "path to mz file"}],
                "close"=>[method(:close), "close file", {"file" => "path or id of file to close"}],
                "print"=>[method(:info), "print info about mz objects", {"what" => "files/header/reloc", "how" => "original/modified"}],
                "save"=>[method(:save), "save current file"],
                "append"=>[method(:append), "add bytes to current file", {"what" => "file/string/bytes", "value" => "value of bytes", "size" => "size of bytes"}],
                "replace"=>[method(:replace), "replace added bytes", {"what" => "file/string/bytes", "value" => "value of bytes", "size" => "size of bytes"}],
                "revert"=>[method(:revert), "revert changes"],
                "hex"=>[method(:hex), "print hex file", {"ofs" => "data offset", "size" => "data size", "how"=>"original/modified", "disp" => "code/file"}],
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
            i,res=MZEnv.instance.s2i_nt(id)
            if res
                raise "Bad file id: " + i.to_s if @files.length < i || i < 0
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
                    puts "Opened files:"
                    @files.each.with_index{|mz,i|
                        puts "#{i}:\t#{mz.path}"
                        curid=i if mz == @cur
                    }
                    puts "Current file: (#{curid}) #{@cur.path}"
                    puts
                else
                    puts "No files opened"
                end
            else
                raise "MZ file not loaded" if !@cur
                @cur.print(what, params['how'])
            end
        end


        def use(params)
            App::get().col.on = true
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
            @cur = @files[0] if !@cur && @files.length > 0
            App::get().col.on = false if @files.length == 0
            info()
        end

        def cur()
            raise "No MZ selected." if !@cur
            return @cur
        end


        def save(params)
            cur().save()
        end

        def append(params)
            cur().append(params['what'], params['value'], params['size'])
        end

        def replace(params)
            cur().replace(params['what'], params['value'], params['size'])
        end


        def revert(params)
            cur().revert()
        end

        def hex(params)
            cur().hex(params['ofs'], params['size'], params['how'], params['disp'])
        end


        def job(params)
            cmd = params['cmd']
            if cmd.length==0
                App::get().setShell('mz')
                return
            end
            if params['help']
                params['command'] = params['help']
                help(params)
                return
            end
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
