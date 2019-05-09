require 'resedit/app/app_command'
require 'resedit/mz/multiexe'
require 'resedit/classes/env'

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
            addOption('help', 'h', false, 'help on mz commands')
            @cmds = {
                "help"=>[method(:help), "show help on mz commands", {"command" => "command to show help on"}],
                "use"=>[method(:use), "select mz file", {"file" => "path to mz file"}],
                "save"=>[method(:save), "save current file",{"filename" => "filename fir saving", "final"=>"don't save changes"}],
                "close"=>[method(:close), "close file", {"file" => "path or id of file to close"}],
                "print"=>[method(:info), "print info about mz objects", {"what" => "files/header/reloc/changes", "how" => "original/modified"}],
                "append"=>[method(:append), "add bytes to current file", {"value" => "value", "type" => "value type"}],
                "replace"=>[method(:replace), "replace added bytes", {"value" => "value", "type"=>"value type"}],
                "change"=>[method(:change), "change bytes at offset", {"ofs" => "data ofset", "value" => "value", "disp" => "code/file", "type"=>"value type"}],
                "reloc"=>[method(:reloc), "add relocation", {"offset" => "reloc offset", "target" => "address reloc points to"}],
                "revert"=>[method(:revert), "revert changes", {"ofs"=>"change offset/all"}],
                "hex"=>[method(:hex), "print hex file", {"ofs" => "data offset", "size" => "data size", "how"=>"original/modified", "disp" => "code/file"}],
                "dasm"=>[method(:dasm), "print disasm", {"ofs" => "data offset", "size" => "data size", "how"=>"original/modified"}],
                "eval"=>[method(:expr), "print expression", {"expr" => "expression"}],
                "dump"=>[method(:dump), "dump exe parts", {"out" => "output filename", "parts"=>"list of parts", "how"=>"original/modified"}],
                "relocfind"=>[method(:relocfind), "find relocation with value", {"value" => "value", "type"=>"value type"}],
                "stringfind"=>[method(:stringfind), "search for strings in exe", {"size"=>"min string size"}],
            }
            @shorters = {"p"=>"print", "e"=>"eval"}
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
            #env = !@cur ? Env.new(self) : @cur.env
            env = Env.new()
            i,res =  env.s2i_nt(id)
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
            mz = getfile(params['file'])
            if mz==nil
                mz = Multiexe.new(params['file'])
                @files+=[mz]
            end
            @cur = mz
            info()
        end


        def close(params)
            mz = getfile(params['file'])
            raise "File not found: "+fn if nil == mz
            @files -= [mz]
            @cur = nil if @cur == mz
            mz.close()
            mz = nil
            @cur = @files[0] if !@cur && @files.length > 0
            info()
        end


        def cur()
            raise "No MZ selected." if !@cur
            return @cur
        end


        def save(params)
            cur().save(params['filename'], params['final'])
        end


        def append(params)
            cur().append(params['value'], params['type'])
        end


        def replace(params)
            cur().replace(params['value'], params['type'])
        end


        def change(params)
            cur().change(params['ofs'], params['value'], params['disp'], params['type'])
        end

        def reloc(params)
            cur().reloc(params['offset'],params['target'])
        end

        def relocfind(params)
            cur().relocfind(params['value'], params['type'])
        end

        def stringfind(params)
            cur().stringfind(params['size'])
        end

        def revert(params)
            cur().revert(params['ofs'])
        end


        def hex(params)
            cur().hex(params['ofs'], params['size'], params['how'], params['disp'])
        end


        def dasm(params)
            cur().dasm(params['ofs'], params['size'], params['how'])
        end

        def expr(params)
            env = @cur && @cur.env ? @cur.env : Env.new()
            puts env.s2i(params['expr'])
        end

        def dump(params)
            cur().dump(params['out'], params['parts'], params['how'])
        end


        def job(params)
            cmd = params['cmd']
            cmd = @shorters[cmd] if @shorters[cmd]
            if cmd.length==0 || File.exist?(cmd)
                App::get().setShell('mz')
                return if cmd.length == 0
                params['p1'] = cmd
                cmd = "use"
            end
            if cmd=="valueof"
                cur().valueof(params['p1'], params['p2'])
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
