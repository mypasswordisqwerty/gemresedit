require 'resedit/app/app_command'
require 'resedit'

module Resedit

    class VersionCommand < AppCommand
        def initialize
            super(['version','--version'])
        end
        def job(params)
            log('%s v%s %s. Resedit v%s.',App::get().name, App.get().version, App::get().copyright, Resedit::VERSION)
        end
    end

    class ExitCommand < AppCommand
        def initialize
            super(['quit','q', 'exit'])
        end
        def job(params)
            App::get().quit();
        end
    end


    class HelpCommand < AppCommand
        def initialize
            super(['help','--help','-h','/?'])
            addParam('command', 'help on specific command', '')
        end
        def job(params)
            if params['command'] != ''
                cmd = App.get().cmds[params['command']]
                raise "Unknown command: #{params['command']}" if !cmd
                puts "Command:"
                print "\t" + cmd.names[0]
                if cmd.names.length > 1
                    print ' ( '
                    cmd.names.each.with_index{|n,i|
                        print n + ' ' if i > 0
                    }
                    print ')'
                end
                puts
                puts "Usage:"
                print "\t" + cmd.names[0] + ' <options>'
                cmd.params.each{|p|
                    print ' '
                    print '[' if p[:def] != nil
                    print p[:name]
                    print ']' if p[:def] != nil
                }
                puts
                puts "Params:"
                cmd.params.each{|p|
                    puts "\t" + p[:name] + "\t - " + p[:descr]
                }
                puts "Options:"
                rohash = cmd.ohash.invert
                cmd.opts.each{|n, o|
                    nm = "\t--"  + n
                    nm += '=' if o[:param]==nil
                    nm += ", -" + rohash[o[:name]] if rohash[o[:name]]
                    puts nm + "\t - " + o[:descr]
                }
            else
                App.get().commands.each{|c|
                    puts c.names[0]
                }
            end
        end
    end


    class ScriptCommand < AppCommand
        def initialize
            super(['script', '--script', '-s'])
            addParam('file', 'script file')
        end
        def job(params)
            App::get().logd("running script %s", params['file']);
            script = []
            text=File.open(params['file']).read
            text.gsub!(/\r\n?/, "\n")
            text.each_line {|line|
                script += [App.get().parseCommand(line.chomp())]
            }
            script.each{|cmd|
                cmd[0].run(cmd[1]) if cmd
            }
        end
    end


    class ShellCommand < AppCommand
        def initialize
            super(['shell'])
            addParam('shell', 'shell name', "")
        end
        def job(params)
            App::get().setShell(params['shell'])
        end
    end


end
